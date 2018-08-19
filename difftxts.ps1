
[CmdletBinding()]
param
(
  [Parameter (Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
  [System.String]$p,
  [Parameter (Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
  [System.String]$q
)
begin
{
  $scriptname=$MyInvocation.MyCommand.Name
  trap
  {
    $error[0]|Out-File ("{0}.{1}.err" -f @($scriptname,(Get-Date -Format "yyyyMMddHHmmss")))
    exit 1
  }
  if (($null -eq $p) -or ($p.Length -eq 0) -or (-not (Test-Path $p)))
  {
    throw "file not found...{0}" -f $p
  }
  if (($null -eq $q) -or ($q.Length -eq 0) -or (-not (Test-Path $q)))
  {
    throw "file not found...{0}" -f $q
  }
  $csvheader=@("path","xpath","text")
  $o=((Get-ChildItem $q).Name -replace '^\w+:\\([\w|\W]+)$','$1') -replace '\\','_'
  $now=Get-Date -Format "yyyyMMddHHmmss"
  "{0}:{1} starts at {2}..." -f @($scriptname,$o,$now)|Write-Output
}
process
{
  try
  {
    $ht=[ordered]@{}
    Get-Content $p|ConvertFrom-Csv -Delimiter "`t" -Header $csvheader|Select-Object $csvheader[1..($csvheader.Count-1)]|ForEach-Object `
    {
      $l=New-Object 'System.Collections.Generic.LinkedList[System.String]'
      $l.AddFirst($_.($csvheader[2]))
      $ht[$_.($csvheader[1])]=$l
    }
    Get-Content $q|ConvertFrom-Csv -Delimiter "`t" -Header $csvheader|Select-Object $csvheader[1..($csvheader.Count-1)]|Sort-Object $csvheader[1]|ForEach-Object `
    {
      if ($ht.keys -ccontains $_.($csvheader[1]))
      {
        $ht[$_.($csvheader[1])].AddLast($_.($csvheader[2]))
      }
      else
      {
        $l=New-Object 'System.Collections.Generic.LinkedList[System.String]'
        $l.AddFirst("[none]")
        $l.AddLast($_.($csvheader[2]))
        $ht[$_.($csvheader[1])]=$l
      }
    }
    $diff=[ordered]@{}
    $match=[ordered]@{}
    foreach ($k in $ht.keys)
    {
      $l=$ht[$k]
      if ($l.Count -eq 2)
      {
        if ($l.First.Value.Equals($l.Last.Value))
        {
          $match[$k]=[System.String]::Join("`t",$l)
        }
        else
        {
          $diff[$k]=[System.String]::Join("`t",$l)
        }
      }
      else
      {
        if ($l.Count -eq 1)
        {
          $diff[$k]="{0}`t[none]" -f $l.First.Value
        }
        else
        {
          # omit #Comment tag.
          if ($k -notmatch "^/[\w|\W]+#Comment\s*$")
          {
            throw "too many arguments ({0}):{1}...{2}" -f @($l.Count,$k,[System.String]::Join("...",$l))
          }
        }
      }
    }
    foreach ($k in $diff.keys)
    {
      "{0}`t{1}" -f @($k,$diff[$k])|Out-File ("{0}.{1}.diff" -f @($o,$now)) -Append
    }
    foreach ($k in $match.keys)
    {
      "{0}`t{1}" -f @($k,$match[$k])|Out-File ("{0}.{1}.match" -f @($o,$now)) -Append
    }
  }
  catch
  {
     $error[0]|Out-File ("{0}.{1}.err" -f @($o,$now)) -Append
  }
}
end
{
  "{0}:{1} completed at {2}..." -f @($scriptname,$o,(Get-Date -Format "yyyyMMddHHmmss"))|Write-Output
}
