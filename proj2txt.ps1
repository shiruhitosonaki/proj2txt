
[CmdletBinding()]
param
(
  [Parameter (Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
  [System.String]$path
)
begin
{
  if (($null -eq $path) -or ($path.Length -eq 0) -or (-not (Test-Path $path)))
  {
    $p=".\"
    ""|Write-Output
  }
  $scriptname=$MyInvocation.MyCommand.Name
  $now=Get-Date -Format "yyyyMMddHHmmss"
  $abcdefg =
  {
    [CmdletBinding()]
    param
    (
      [Parameter (Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
      [System.Xml.XPath.XPathNodeIterator]$x,
      [Parameter (Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=2)]
      [System.Collections.Generic.LinkedList[System.String]]$l
    )
    begin
    {
    }
    process
    {
      do
      {
        #if ($x.Current.NodeType -eq [System.Xml.XPath.XPathNodeType]::Comment)
        #{
        #  continue
        #}
        $i=New-Object System.Text.StringBuilder
        if ($x.Current.NodeType -ne [System.Xml.XPath.XPathNodeType]::Attribute)
        {
          if ($x.Current.NodeType -eq [System.Xml.XPath.XPathNodeType]::Comment)
          {
            $l.AddLast("#{0}" -f [System.Xml.XPath.XPathNodeType]::Comment)
          }
          else
          {
            if($x.Current.Name.Length -gt 0)
            {
              $l.AddLast("/{0}" -f $x.Current.Name)
            }
          }
        }
        if ($x.Current.MoveToFirstAttribute())
        {
          $i.Append($l.Last.Value)
          $l.RemoveLast()
          $ht=[ordered]@{}
          do
          {
            $ht["@{0}" -f $x.Current.Name]=$x.Current.Value
          }
          while ($x.Current.MoveToNextAttribute())
          foreach ($k in $ht.Keys)
          {
            $i.Append("{0}:{1}" -f @($k,$ht[$k]))
          }
          $l.AddLast($i.ToString())
          if ($x.Current.MoveToParent())
          {
            "back to the element node ({0}) ..." -f $x.Current.Name|Write-Output
          }
        }
        if ($x.Current.MoveToFirstChild())
        {
          &$abcdefg -x $x -l $l
        }
        else
        {
          $i.Append("{0}={1}" -f @($l.Last.Value,$(if ($x.Current.Value.Length -gt 0) {$x.Current.Value} else {"[null]"})))
          $l.RemoveLast()
          $l.AddLast($i.ToString())
          [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
          $l.RemoveLast()
        }
      }
      while ($x.Current.MoveToNext())
      if ($x.Current.MoveToParent())
      {
        "move to the parent node ({0}) ..." -f $x.Current.Name|Write-Output
      }
    }
    end
    {
    }
  }
}
process
{
  foreach ($i in Get-ChildItem $p -Recurse | Where-Object {$_.Extension -match ".*proj"}) {
    try
    {
      $l=New-Object System.Collections.Generic.LinkedList[System.String]
      $l.Add("{0}," -f $i.FullName)
      $x=([xml](Get-Content $i.FullName)).CreateNavigator().Select("/*")
      if ($x.Current.MoveToFirstChild())
      {
        &$abcdefg -x $x -l $l
      }
    }
    catch
    {
       $i|Out-File ("{0}_{1}.err" -f @($now,$scriptname)) -Append
       $error[0]|Out-File ("{0}_{1}.err" -f @($now,$scriptname)) -Append
    }
  }
}
end
{
  "{0} is terminated ..." -f $scriptname|Write-Output
}
