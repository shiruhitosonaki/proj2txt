
[CmdletBinding()]
param
(
  [Parameter (Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
  [System.String]$path,
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
  if (($null -eq $path) -or ($path.Length -eq 0) -or (-not (Test-Path $path)))
  {
    throw "file not found...{0}" -f $path
  }
  if (($null -eq $q) -or ($q.Length -eq 0) -or (-not (Test-Path $q)))
  {
    throw "file not found...{0}" -f $q
  }
  $csvheader=@("xpath","text","reftext")
  $o=((Get-ChildItem $q).Name -replace '^\w+:\\([\w|\W]+)$','$1') -replace '\\','_'
  $now=Get-Date -Format "yyyyMMddHHmmss"
  "{0}:{1} starts at {2}..." -f @($scriptname,$o,$now)|Write-Output
  $o2="{0}.{1}" -f @($o,$now)
}
process
{
  try
  {
    $types=New-Object 'System.Collections.ArrayList'
    $ids=New-Object 'System.Collections.ArrayList'
    foreach ($p in Get-ChildItem $path -Recurse|Where-Object {$_.Extension -match ".txt"})
    {
      $i=New-Object 'System.Text.StringBuilder'
      Get-Content $p|ConvertFrom-Csv -Delimiter "`t" -Header $csvheader|Select-Object $csvheader[0..($csvheader.Count-2)]|Sort-Object $csvheader[0]|ForEach-Object `
      {
        $i.Append("{0}:={1}" -f @($csvheader[0],$csvheader[1]))
      }
      $s=$i.ToString()
      $j=0
      for (;$j -lt $ids.Count;$j++)
      {
        if ($s.Equals($ids[$j]))
        {
          $types[$j].Add($p.Name)
          break
        }
      }
      if ($j -ge $ids.Count)
      {
        $l=New-Object 'System.Collections.ArrayList'
        $l.Add($p.Name)
        $types.Add($l)
        $ids.Add($s)
      }
    }
    for ($i=0;i -lt $ids.Count;$i++)
    {
      "{0}`t_____" -f $ids[$i]|Out-File ("{0}.diff" -f $o2) -Append
      foreach ($j in $types[$i])
      {
        "{0}`t{1}" -f @($ids[$i],$j)|Out-File ("{0}.diff" -f $o2) -Append
      }
    }
  }
  catch
  {
     $error[0]|Out-File ("{0}.err" -f $o2) -Append
     return 2
  }
}
end
{
  "{0}:{1} completed at {2}..." -f @($scriptname,$o,(Get-Date -Format "yyyyMMddHHmmss"))|Write-Output
  "{0}.diff" -f $o2|Out-String
  return 0
}
