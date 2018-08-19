
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
  "{0} starts at {1}..." -f @($scriptname,$now)|Write-Output
  $abcdefg =
  {
    [CmdletBinding()]
    param
    (
      [Parameter (Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
      [System.Xml.XPath.XPathNodeIterator]$x,
      [Parameter (Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
      [System.Collections.Generic.LinkedList[System.String]]$l,
      [Parameter (Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=2)]
      [System.String]$o
    )
    begin
    {
      if ($o.Length -eq 0)
      {
        $o=Get-Date -Format "yyyyMMddHHmmss"
      }
      $hasSibling=$false
      $i=New-Object 'System.Text.StringBuilder'
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
              "move to the first child node ({0})" -f $x.Current.Name|Write-Output
              $l.AddLast($i.ToString())
              &$abcdefg -x $x -l $l -o $o
            }
            else
            {
              $i.Append("`t[null]")
              $l.AddLast($i.ToString())
              #[System.String]::Join("",$l)|Out-File ("{0}.txt" -f $o) -Append
              $hasSibling=$true
            }
            break
          }
          ([System.Xml.XPath.XPathNodeType]::Comment.ToString())
          {
            $l.AddLast("#Comment`t{0}" -f ($x.Current.Value -replace "\s{2,}","[ws]"))
            #[System.String]::Join("",$l)|Out-File ("{0}.txt" -f $o) -Append
            $hasSibling=$true
            break
          }
          ([System.Xml.Xpath.XpathNodeType]::Text.ToString())
          {
            $l.AddLast("`t{0}" -f ($x.Current.Value -replace "\s{2,}","[ws]"))
            #[System.String]::Join("",$l)|Out-File ("{0}.txt" -f $o) -Append
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
          [System.String]::Join("",$l)|Out-File ("{0}.txt" -f $o) -Append
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
  foreach ($i in Get-ChildItem $p -Recurse | Where-Object {$_.Extension -match ".*proj"})
  {
    try
    {
      $l=New-Object 'System.Collections.Generic.LinkedList[System.String]'
      $l.Add("{0}`t" -f $i.FullName)
      $x=([xml](Get-Content $i.FullName)).CreateNavigator().Select("/*")
      if ($x.Current.MoveToFirstChild())
      {
        $o="{0}_{1}" -f @($now, (($i.FullName -replace '^\w+:\\([\w|\W]+)$','$1') -replace '\\','_'))
        &$abcdefg -x $x -l $l -o $o
      }
    }
    catch
    {
       $i|Out-File ("{0}__{1}.err" -f @($now,$scriptname)) -Append
       $error[0]|Out-File ("{0}__{1}.err" -f @($now,$scriptname)) -Append
    }
  }
}
end
{
  "{0} terminated at {1}..." -f @($scriptname,(Get-Date -Format "yyyyMMddHHmmss"))|Write-Output
}
