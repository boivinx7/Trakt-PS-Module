$Rss = "https://trakt.tv/calendars/my/shows.atom?slurm=c108933e9b1e70e3c3e33ae05deba3c4"

$Request = Invoke-WebRequest -Uri $Rss

$FeedContent = [XML]$Request.Content
$Titles = $FeedContent.feed.entry | Where-Object {$_.title -like "*big little*"}

foreach ($Title in $Titles)
{
    (((($Title.id) -split ",")[1]) -split '/')[1]
}