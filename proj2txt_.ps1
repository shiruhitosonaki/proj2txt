
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
      $isLeaf=$false
      $i=New-Object System.Text.StringBuilder
    }
    process
    {
      do
      {
        #if ($x.Current.NodeType -eq [System.Xml.XPath.XPathNodeType]::Comment)
        #{
        #  continue
        #}
        $i.Length=0
     #   if ($isLeaf)
    #    {
    #      $l.RemoveLast()
    #      $isLeaf=$false
    #    }
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
            "back to the element node ({0}) ..." -f $x.Current.Name|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
          }
        }
        if ($x.Current.MoveToFirstChild())
        {
          "child of ({0}) ...{1}" -f @($x.Current.Name,$l.Last.Value)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
          &$abcdefg -x $x -l $l

          "--child of ({0}) ...{1}" -f @($x.Current.Name,$l.Last.Value)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
        }
        else
        {
          $i.Length=0
          $i.Append("{0}={1}" -f @($l.Last.Value,$(if ($x.Current.Value.Length -gt 0) {$x.Current.Value} else {"[null]"})))
          $l.RemoveLast()
          $l.AddLast($i.ToString())
          [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
          "top...{0}" -f [System.String]::Join("",$l)|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append

          if ($x.Current.NodeType -ne [System.Xml.XPath.XPathNodeType]::Comment)
          {
            if (($x.Current.Name -eq $null) -or ($x.Current.Name.Length -eq 0))
            {
              if ($x.Current.MoveToParent())
              {
                "++move to the parent node of ({0}) ..." -f $x.Current.Name|Out-File ("{0}_{1}.txt" -f @($Script:now,$Script:scriptname)) -Append
              }
            }
          }
          $l.RemoveLast()
          $isLeaf=$true
        }
      }
      while ($x.Current.MoveToNext())
   #   if ($l.Count -gt 0)
      if ($x.Current.MoveToParent())
      {
      
    #    if (-not $isLeaf)
    #    {
          $l.RemoveLast()
          $isLeaf=$false
    #    }
    #    else
    #    {
    #      $isLeaf=$false
    #    }
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
