@{
  RootModule        = 'pure-pwsh.psm1'
  ModuleVersion     = '0.6.2'
  GUID              = '94d168c3-c48f-4937-bc82-4d54b5b9e777'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'pure prompt for powershell'
  PowerShellVersion = '5.0'
  
  FunctionsToExport = 'Set-PureOption'
  VariablesToExport = 'pure'
  AliasesToExport   = '*'

  PrivateData       = @{
    PSData = @{
      Tags       = @('pure', 'prompt')
      LicenseUri = 'https://github.com/nickcox/pure-pwsh/blob/master/LICENSE'
      ProjectUri = 'https://github.com/nickcox/pure-pwsh'
    }
  }
}
