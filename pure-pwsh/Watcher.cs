#pragma warning disable 4014
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Reactive.Linq;
using System.Diagnostics;
using System.Reactive.Concurrency;
using System.Timers;
using LibGit2Sharp;

using static System.Reactive.Linq.Observable;

namespace PurePwsh
{
    public class Watcher : IDisposable
    {
        public event EventHandler StatusChanged;
        public event EventHandler LogEvent;

        private readonly IDisposable _eventSubscription;
        private readonly Timer _fetchTimer = new Timer { AutoReset = true };
        private readonly FileSystemWatcher _fsw = new FileSystemWatcher() { IncludeSubdirectories = true };

        private GitStatus _status = new GitStatus();

        public Watcher(string initialDirectory, double fetchInterval = 0, int throttleInterval = 250)
        {
            _eventSubscription =
              Merge(
                FromEventPattern<FileSystemEventHandler, FileSystemEventArgs>(x => _fsw.Changed += x, x => _fsw.Changed -= x),
                FromEventPattern<FileSystemEventHandler, FileSystemEventArgs>(x => _fsw.Deleted += x, x => _fsw.Deleted -= x)
              )
              .SampleFirst(TimeSpan.FromMilliseconds(throttleInterval))
              .Subscribe(x => UpdateGitStatus(x.EventArgs));

            GitFetchMs = fetchInterval;
            PwdChanged(initialDirectory);

            GitFetch();
            _fetchTimer.Elapsed += (s, a) => GitFetch();
        }

        public GitStatus Status
        {
            get => _status;

            private set
            {
                if (!value.HasChanged(_status))
                    return;

                _status = value;
                if (!string.IsNullOrWhiteSpace(value.GitPath))
                    StatusChanged?.Invoke(this, EventArgs.Empty);
            }
        }

        public double GitFetchMs
        {
            get => _fetchTimer.Interval;
            set
            {
                _fetchTimer.Interval = Math.Max(value, 1); // <= 0 is an ArgumentException
                _fetchTimer.Enabled = value > 0;
            }
        }

        async Task GitFetch()
        {
            if (string.IsNullOrWhiteSpace(_status.GitPath))
                return;

            LogEvent?.Invoke(this, new LogEventArgs("Fetching from git..."));

            // if there's a problem here, try to avoid taking down the entire session
            try
            {
                await Task.Run(
                  () =>
                  {
                      using (var repo = new Repository(_status.GitPath))
                      {
                          var remote = repo.Network.Remotes["origin"];
                          if (remote.Url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                          {
                              var refSpecs = remote.FetchRefSpecs.Select(x => x.Specification);
                              Commands.Fetch(repo, remote.Name, refSpecs, null, "");
                          }
                          else
                          {
                              LogEvent?.Invoke(this, new LogEventArgs(
                                "SSH fetch not supported in libgit2. Invoking git directly."));

                              Process.Start(
                                new ProcessStartInfo
                                {
                                    WorkingDirectory = _status.GitPath,
                                    FileName = "git",
                                    Arguments = "fetch",
                                    UseShellExecute = false,
                                    CreateNoWindow = true
                                });
                          }
                      }
                  });
            }

            catch (Exception ex)
            {
                LogEvent?.Invoke(this, new LogEventArgs($"Error fetching from git: {ex}"));
            }
        }

        public async Task UpdateGitStatus(FileSystemEventArgs args = null, string path = null)
        {
            path = path ?? _status.GitPath;
            if (string.IsNullOrWhiteSpace(path))
                return;

            LogEvent?.Invoke(this, new LogEventArgs($"{args?.FullPath ?? "(pwd)"} was modified."));

            // if there's a problem here, try to avoid taking down the entire session
            try
            {
                await Task.Run(
                    () =>
                    {
                        using (var repo = new Repository(path))
                        {
                            var status = repo.RetrieveStatus(new StatusOptions { IncludeIgnored = false });
                            var branch = repo.Head;
                            var ahead = branch.TrackingDetails.AheadBy;
                            var behind = branch.TrackingDetails.BehindBy;

                            Status = new GitStatus
                            {
                                Dirty = status.IsDirty,
                                Ahead = ahead > 0,
                                Behind = behind > 0,
                                BranchName = branch.FriendlyName,
                                GitPath = repo.Info.Path
                            };
                        }
                    }
                );
            }

            catch (Exception ex)
            {
                LogEvent?.Invoke(this, new LogEventArgs($"Error updating git status: {ex}"));
            }
        }

        public async Task PwdChanged(string newDirectory)
        {
            var maybeRepoPath = Repository.Discover(newDirectory);
            if (maybeRepoPath != null && maybeRepoPath != Status.GitPath)
            {
                _fsw.Path = Directory.GetParent(Path.GetDirectoryName(maybeRepoPath)).FullName;
                _fsw.EnableRaisingEvents = true;

                await UpdateGitStatus(path: maybeRepoPath);
            }

            else
            {
                _fsw.EnableRaisingEvents = false;
                Status = new GitStatus();
            }
        }

        public void Dispose()
        {
            _fsw?.Dispose();
            _eventSubscription?.Dispose();
        }

        public override string ToString()
        {
            return Status.ToString();
        }
    }

    public class GitStatus
    {
        public bool Dirty;
        public bool Ahead;
        public bool Behind;
        public string BranchName;
        public string GitPath;

        public override string ToString()
        {
            return $"{BranchName} ({(Dirty ? "!" : "")}{(Ahead ? "+" : "")}{(Behind ? "-" : "")})";
        }

        public bool HasChanged(GitStatus other) =>
            other.Dirty != Dirty ||
            other.Ahead != Ahead ||
            other.Behind != Behind ||
            other.BranchName != BranchName ||
            other.GitPath != GitPath;
    }

    public class LogEventArgs : EventArgs
    {
        public LogEventArgs(string output) => Output = output;

        public string Output { get; }
    }

    public static class ObservableExtensions
    {
        public static IObservable<T> SampleFirst<T>(
            this IObservable<T> source,
            TimeSpan sampleDuration,
            IScheduler scheduler = null)
        {
            scheduler = scheduler ?? Scheduler.Default;
            return source.Publish(ps =>
                ps.Window(() => ps.Delay(sampleDuration, scheduler))
                  .SelectMany(x => x.Take(1)));
        }
    }
}