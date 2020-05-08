@{
  RootModule        = 'pure-pwsh.psm1'
  ModuleVersion     = '0.8.0'
  GUID              = '94d168c3-c48f-4937-bc82-4d54b5b9e777'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'pure prompt for powershell'
  PowerShellVersion = '7.0'

  FunctionsToExport = 'Set-PureOption'
  VariablesToExport = 'pure'
  AliasesToExport   = '*'

  PrivateData       = @{
    PSData = @{
      Prerelease = 'beta1'
      Tags       = @('pure', 'prompt')
      LicenseUri = 'https://github.com/nickcox/pure-pwsh/blob/master/LICENSE'
      ProjectUri = 'https://github.com/nickcox/pure-pwsh'
    }
  }
}
