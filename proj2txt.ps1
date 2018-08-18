
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
        if ($hasSibling)
        {
          $l.RemoveLast()
          $hasSibling=$false
        }
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
                "back to the element node ({0}) ..." -f $x.Current.Name|Write-Output
              }
            }
            if ($x.Current.MoveToFirstChild())
            {
              "move to the child node ({0})" -f $x.Current.Name|Write-Output
              $l.AddLast($i.ToString())
              &$abcdefg -x $x -l $l
            }
            else
            {
              $i.Append(":=[null]")
              $l.AddLast($i.ToString())
              #[System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
              $hasSibling=$true
            }
            break
          }
          ([System.Xml.XPath.XPathNodeType]::Comment.ToString())
          {
            $l.AddLast("#Comment:={0}" -f $x.Current.Value)
            #[System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
            $hasSibling=$true
            break
          }
          ([System.Xml.Xpath.XpathNodeType]::Text.ToString())
          {
            $l.AddLast(":={0}" -f $x.Current.Value)
            #[System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
            $hasSibling=$true
            break
          }
          default
          {
            throw "found unexpected tag:{0}" -f $x.Current.NodeType.ToString()
          }
        }
        if ($hasSibling)
        {
          [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
        }
      }
      while ($x.Current.MoveToNext())
      if ($x.Current.MoveToParent())
      {
        "move to the parent node ({0})" -f $x.Current.Name|Write-Output
        if ($hasSibling)
        {
          $l.RemoveLast()
          $hasSibling=$false
        }
        $l.RemoveLast()
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
