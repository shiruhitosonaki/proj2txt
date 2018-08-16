
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
      $hasSibling=$false
      $i=New-Object System.Text.StringBuilder
    }
    process
    {
      do
      {
        $i.Length=0
        switch ($x.Current.NodeType.ToString())
        {
          ([System.Xml.XPath.XPathNodeType]::Element.ToString())
          {
            $i.Append("/{0}" -f $x.Current.Name)
            if ($x.Current.MoveToFirstAttribute())
            {
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
              if ($x.Current.MoveToParent())
              {
                "back to the element node ({0}) ..." -f $x.Current.Name|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
              }
            }
            if ($x.Current.MoveToFirstChild())
            {
        "{0} --- {1}" -f @($l.Count,$l.Last.Value)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
              $l.AddLast($i.ToString())
              &$abcdefg -x $x -l $l
            }
            else
            {
              $i.Append("=[null]")
              $l.AddLast($i.ToString())
              [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
              $l.RemoveLast()
              $hasSibling=$true
            }
            break
          }
          ([System.Xml.XPath.XPathNodeType]::Comment.ToString())
          {
            $l.AddLast("#{0}={1}" -f @($x.Current.Name,$x.Current.Value))
            [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
            $l.RemoveLast()
            $hasSibling=$true
            break
          }
          ([System.Xml.Xpath.XpathNodeType]::Text.ToString())
          {
            $l.AddLast("={0}" -f $x.Current.Value)
            [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
            $l.RemoveLast()
            $hasSibling=$true
            break
          }
        }
        "{0} -- {1}" -f @($l.Count,$l.Last.Value)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
      }
      while ($x.Current.MoveToNext())
      if ($x.Current.MoveToParent())
      {
   #     if (-not $hasSibling)
        {
          $l.RemoveLast()
        }
        "move to the parent node of ({0}) ...{1}" -f @($x.Current.Name,$l.Count)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
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
