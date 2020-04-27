Import-Module "$PSScriptRoot/../pure-pwsh/pure-pwsh.psd1" -Force

Describe 'pure-pwsh' {

  BeforeAll {
    pushd
    New-Item -ItemType Directory -Path TestDrive:/repo1
  }

  AfterAll {
    popd
  }

  BeforeEach {
    cd TestDrive:/repo1
  }

  InModuleScope pure-pwsh {

    function DoBeforeIdle($block) {
      &$block
      prompt
      &$OnIdleCallback $true # prompt is updated after OnIdle
    }

    Describe 'non-repository directory' {
      It 'shows the current directory' {
        prompt | Should -Match 'repo1\W'
        $pure._state.gitDir | SHould -BeNullOrEmpty
      }
    }

    Describe 'basic git operations' {
      It 'shows no commits yet in new repository' {
        git init

        $null = prompt # updates current git directory
        $pure._state.gitDir | Should -Match 'repo1/.git$'

        DoBeforeIdle { }

        $pure._state.status.dirty | Should -Be $false
        $pure._state.status.branch | Should -Be 'No commits yet on master'
        prompt | Should -Match 'No commits yet on master\W'
      }

      It 'shows the dirty marker after creating a file' {
        DoBeforeIdle { Add-Content test.txt 'foo' }

        $pure._state.status.dirty | Should -Be $true
        $pure._state.status.branch | Should -Be 'No commits yet on master'
        prompt | Should -Match 'No commits yet on master\*\W'
      }

      It 'does not show the dirty marker once the file is committed' {
        DoBeforeIdle { git add test.txt && git commit -m 'first' }

        $pure._state.status.dirty | Should -Be $false
        $pure._state.status.branch | Should -Be 'master'
        prompt | Should -Match 'master\W'
      }

      It 'shows remote status when remote is behind' {
        DoBeforeIdle {
          git init --bare ../repo1-remote.git
          git remote add origin ('file://' + (Get-Item ../repo1-remote.git).FullName)
          git push -u origin master *> $null
        }

        $pure._state.status.ahead | Should -Be $false

        Add-Content test.txt 'bar'
        DoBeforeIdle { git add test.txt && git commit -m 'second' }

        $pure._state.status.ahead | Should -Be $true
        prompt | Should -Match $pure.UpChar

        DoBeforeIdle { git push *> $null }
        $pure._state.status.ahead | Should -Be $false
        prompt | Should -Not -Match $pure.UpChar
      }

      It 'shows remote status when remote is ahead' {
        DoBeforeIdle {
          cd TestDrive:/
          git clone repo1-remote.git repo1-clone *> $null
          cd repo1-clone
          Add-Content test.txt 'baz'
          git add test.txt && git commit -m 'from clone'
        }

        $pure._state.status.ahead | Should -Be $true
        prompt | Should -Match $pure.UpChar

        DoBeforeIdle {
          git push *> $null
          cd ../repo1
          git fetch *> $null
        }

        $pure._state.status.behind | Should -Be $true
        prompt | Should -Match $pure.DownChar

        DoBeforeIdle {
          git pull *> $null
        }

        $pure._state.status.behind | Should -Be $false
        prompt | Should -Not -Match $pure.DownChar
      }

      It 'handles changing into a repository that has new changes' {
        DoBeforeIdle {
          $pure._state.gitDir | Should -Not -BeNullOrEmpty
          $pure._state.status.dirty | Should -Be $false
          cd TestDrive:/
        }

        $pure._state.gitDir | Should -BeNullOrEmpty
        Add-Content repo1/test.txt 'qux'

        DoBeforeIdle {
          cd TestDrive:/repo1
        }

        $pure._state.gitDir | Should -Not -BeNullOrEmpty
        $pure._state.status.dirty | Should -Be $true
      }
    }
  }
}
