## Facebook Data Aggregator ####
## By Vivek Menon ##############
## v.1.2.1 #####################


# Summary -----------------------------------------------------------------


# Todo --------------------------------------------------------------------

# - Run script for all major brands
# - Create 'participation rate' function
# - Incorporate Twitter

# Setup -------------------------------------------------------------------
# Load and install all necessary packages for the script

# Required Packages for dataframes, forecasting, graphical visualization, and development
# Use 'install.packages()' if unavailable. 
#library(zoo)
#library(forecast)
library(ggplot2)
#library(scales)
library(devtools)
library(compare)

# Pull most up to date Github repositories for relevant packages
# Not frequently updated; does not need to be run every time. 
#install_github("pablobarbera/Rfacebook/Rfacebook")
#install_github("pablobarbera/instaR/instaR")

# Required packags for plugging into Facebook API
#library(twitteR) 
library(Rfacebook)

#library(instaR) 
# https://github.com/pablobarbera/instaR/blob/master/examples.R
# https://instagram.com/developer/authentication/?hl=en

setwd("~/Desktop")
getwd()

# Inputs ------------------------------------------------------------------
# Set up script initials; what is the access ftoken, the relevant ids, and other necessary variables

## Access ftoken
# Use token from Facebook Graph API 
# token generated here: https://developers.facebook.com/tools/explorer 
# Lasts two hours, and must be changed depending on page and permissions

ftoken <- "CAACEdEose0cBABXXTGdaqZCMaZAZChBMN1n5ZBeTUTwLET1X4tHQqddmYM0AZCs8gq5SqhzZBVFTA1H9fbQk7s8n5A5VuZB7s4rgwQwj8UkTGPq7UIUhDd7ZBBg8CSTrLYCwensylY3AP7ZBr422xiflf3LZC1pjrAbysGcYZBEZA8jeE4WIbPHkviJeFTJKaWfVcI8ZD"

## User Id 
# Set up the user profile that will be accessing the data (must have all appropriate permissions/be Page Admin)
userid = "10153046308598756"

# Access public personal data; basically a ftoken test
me <- getUsers("me", token=ftoken)
print(me$name)

## Page Id
# Define which page will be used for the data collection. Change id's as necessary. 
# Can use Pagename or ID; ID is generally preferable. Can be found through Facebook Business Manager: https://business.facebook.com/

pageid = me$id

# Define data range for data (2012 is out of bounds for some metrics)

roof = Sys.Date()+1
floor = "2013-01-01"
range = seq(as.Date(floor), as.Date(roof), by="days")

# Acquisition -------------------------------------------------------------
# Grab/Load all Facebook Page & Post data until today for the Page defined.

page <- getPage(pageid, ftoken, n = 5000)

# Processing --------------------------------------------------------------
# Process data to clean dataset and augment it with more data than default fields.
# Check full package documentation for reference: http://cran.r-project.org/web/packages/Rfacebook/Rfacebook.pdf

## Cleaning =================================

# Function to convert Facebook date format to R date format
format.facebook.date <- function(datestring) {
  date <- as.POSIXct(datestring, format = "%Y-%m-%dT%H:%M:%S+0000", tz = "GMT")
}

# Shift a vector up by an amount
shift <- function(x, n){
  c(x[-(seq(n))], rep(NA, n))
}

# Get gcd from vector
gcd <- function(x,y) {
  r <- x%%y;
  return(ifelse(r, gcd(y, r), y))
}

# Create new vectors in dataset with datetime, month, and day formattiong
page$datetime <- format.facebook.date(page$created_time)
page$month <- format(page$datetime, "%Y-%m")
page$day <- format(page$datetime, "%Y-%m-%d")


# Page and Post Datasets
# Split dataset into two for pages and post data
# Create initial null sets
pagedata <- 0
postdata <- 0

## Appending =================================

### Page Metrics ############################# 
# Loop through all dates for the specified metric(s), and append the page dataset with metric values
# Some are automated, others are manual; after the script. Re-run from pull loop if there is an error; should auto-try until values are found. 

# Page Metrics to automatically pull
metrics = c("page_impressions_unique", "page_impressions_paid_unique", "page_engaged_users", "page_fans", "page_stories")
names(metrics) = c("Total Reach",  "Paid Reach", "Engagements", "Likes", "Stories")

# Prep dataset by breaking into weeks 
pagedata <- 0
pagedata <- cbind(page[1:length(range), c("from_id","from_name")],rev(range))
colnames(pagedata) = c("pageid", "page", "date")


divisor = 5
remainder = length(range)%%divisor;
pagedata <- pagedata[1:(nrow(pagedata)-remainder),]

# Start Data Acquisition Loop
for (metric in 1:length(metrics)) {
  
  pagedata <- cbind(NA,pagedata)
  
  print(paste('Finding', names(metrics)[metric],'for',pagedata$page[1]))
  
  if ((metrics)[metric] == 'page_fans') {
    period = 'lifetime'
  } else {
    period = 'day'
  }
  
  hold <- matrix(0, nrow=0, ncol=7)
  
  for (week in 0:((nrow(pagedata)/5)-2)) {
    
    end <- pagedata$date[(week*5)+1]
    start <- pagedata$date[((week+1)*5)+1]
    
    print(paste('Finding', names(metrics)[metric],'for',pagedata$page[1],'from',start,'to',end))
    
    pull <- NULL
    attempt <- 1
    
    while(is.null(pull) && attempt <= 100) {
      attempt <- attempt + 1
      try(
        pull <- getInsights(object_id=pageid, token=ftoken, metric=metrics[metric], period=period, parms=paste0('&since=',start,'&until=',end))
      )
      
      pull$datetime <- format.facebook.date(pull$end_time)
      pull$day <- format(pull$datetime, "%Y-%m-%d")
      
      if ((seq(from=start, to=(end-1), by = "days")[1] == pull$day[1]) & (seq(from=start, to=(end-1), by = "days")[5] == pull$day[5]) == TRUE) {
        print("Found Facebook data matching date range. Storing values.")
      } else {
        print("Did not find Facebook data matching dataset dates. Re-querying.")
        pull <- NULL
      }
    } 
    
    rpull = pull[rev(rownames(pull)),]
    
    hold <- rbind(hold,rpull)
    rawhold <- hold
  }
  
  rhold = hold[rev(rownames(hold)),]
  rhold$value = shift(rhold$value, 1)
  hold = rhold[rev(rownames(rhold)),]
  hold$value[1] = rawhold$value[1]
  
  pagedata[2:(length(hold$day)+1),1] <- (hold$value)
  colnames(pagedata)[1] = paste0(tolower(names(metrics[metric])))
  
  cat("\n\n")
  print(head(pagedata))
  cat("\n")
}

# Page Metrics to manually create
metrics <- c(metrics,"organic reach")
names(metrics)[length(metrics)] <- c("Organic Reach")

pagedata <- cbind((pagedata$`total reach` - pagedata$`paid reach`),pagedata)
colnames(pagedata)[1] = "organic reach" 

# Final dataset formatting
pagedatastore <- pagedata
#pagedata <- pagedatastore
pagedata2 <- pagedata


# reorder and null NA's for excel
pagedata2 <- pagedata2[,c((ncol(pagedata)-2), (ncol(pagedata)-1),(ncol(pagedata)),(1:(ncol(pagedata)-3)))]
pagedata2 <- pagedata2[2:nrow(pagedata2),]
pagedata2[is.na(pagedata2)] <- ""

# store final dataset
pagedata <- pagedata2

### Post Metrics ############################# 
# Loop through all posts for the specified metric(s), and append the post dataset with metric values
# Most are automated, and will continue to retry through errors until a value is found. 
# Manual modifications are run after initial data acquisition. 

postmetrics = c("post_impressions_unique","post_impressions_paid_unique","post_video_views_organic_unique","post_video_views_paid_unique")
names(postmetrics) = c("Total Reach", "Paid Reach","Paid Video Views", "Organic Video Views")

# Populate sets with values from pull
postdata <- 0
postdata <- page[page$created_time > floor,]

# Name column for usability 
colnames(postdata) = c("pageid", "page", "message", "created", "type", "link", "postid", "likes", "comments", "shares", "datetime", "month","day")


rows <- nrow(postdata)
lpostmetrics <- postmetrics

for (pmetric in 1:length(postmetrics)) {
  postdata <- cbind(NA,postdata)
  
  print(paste('Finding', names(postmetrics)[pmetric],'for',postdata$page[1]))
  
  for (post in 1:nrow(postdata)) { 
    
    period <- "lifetime" 
    
    print(paste('Finding', names(postmetrics)[pmetric],'for',postdata$page[1], postdata$type[post],'post:',paste0(substr(postdata$message[post], 1, 80),"...")))
    
    if ((substr((postmetrics)[pmetric], 1, 10) == ('post_video')) & (postdata$type[post] == 'video') & (substr(postdata$link[post], 12, 18) != 'youtube') & (substr(postdata$link[post], 8, 15) != 'youtu.be')) {
      } 
    else if (substr((postmetrics)[pmetric], 1, 10) != ('post_video')) {
      }
    else {
      print('Not a Facebook Video.')
      next()
    }

  postpull <- NULL
  attempt <- 1
  
  while( is.null(postpull) && attempt <= 100) {
    attempt <- attempt + 1
    try(
      postpull <- getInsights(object_id=postdata$postid[post], token=ftoken, metric=postmetrics[pmetric], period=period)
      ,silent=FALSE
    )
  } 
  
  postdata[post,1] <- postpull$value
  
  rows <- (rows-1)
  }
  
  colnames(postdata)[1] = paste0(tolower(names(postmetrics[pmetric])))
  
  cat("\n\n")
  print(head(postdata))
  cat("\n")
}

# Post Metrics to manually create

# Final dataset formatting
postdatastore <- postdata
#postdata <- postdatastore

#head(postdatastore[,c((ncol(postdata)-12),(ncol(postdata)-11),(ncol(postdata)-9),(ncol(postdata)-2), (ncol(postdata)-1),ncol(postdata),(ncol(postdata)-6),(ncol(postdata)-7),(ncol(postdata)-8),(ncol(postdata)-10),(ncol(postdata)-5),(ncol(postdata)-4),(ncol(postdata)-3),(1:(ncol(postdata)-13)))])

# reorder and null NA's for Excel
postdata2 <- postdata
postdata2 <- postdata2[,c((ncol(postdata)-12),(ncol(postdata)-11),(ncol(postdata)-9),(ncol(postdata)-2), (ncol(postdata)-1),ncol(postdata),(ncol(postdata)-6),(ncol(postdata)-7),(ncol(postdata)-8),(ncol(postdata)-10),(ncol(postdata)-5),(ncol(postdata)-4),(ncol(postdata)-3),(1:(ncol(postdata)-13)))]
postdata2[is.na(postdata2)] <- ""

# store final dataset
postdata <- postdata2

# Outputs -----------------------------------------------------------------

# Rename columns for Excel readability 
names(pagedata) = c("Page ID", "Page Name", "Date", rev(names(metrics)))
# output dataset as final csv
write.csv(pagedata, paste0(paste(page$from_name[1],"Page Data",Sys.Date(), sep=" "),".csv"),row.names=FALSE)

# Rename columns for Excel readability 
names(postdata) = c("Page ID", "Page Name", "Created",  "Datetime", "Month", "Day", "Post ID", "Link", "Type", "Message", "Likes", "Comments", "Shares", rev(names(postmetrics)))
# output dataset as final csv
write.csv(postdata, paste0(paste(page$from_name[1],"Post Data",Sys.Date(), sep=" "),".csv"),row.names=FALSE)

# Visuals -----------------------------------------------------------------

pairs(~`Total Reach`+`Paid Reach`+`Organic Reach`+`Likes`+`Engagements`, data=pagedata)

# Monthly aggregation function
aggregate.metric <- function(metric) {
  m <- aggregate(page[[paste0(metric, "_count")]], list(month = page$month), 
                 mean)
  m$month <- as.Date(paste0(m$month, "-15"))
  m$metric <- metric
  return(m)
}


# apply aggregation function entire dataset for every metric defined
df.list <- lapply(c("likes", "comments", "shares"), aggregate.metric)

# Merge all metrics together into a single list
df <- do.call(rbind, df.list)

# visualize evolution in metric
ggplot(df, aes(x = Date, y = , group = metric)) + geom_line(aes(color = metric)) + 
  scale_x_date(breaks = "years", labels = date_format("%Y")) + scale_y_continuous("Number") +
  theme_bw() + theme(axis.title.x = element_blank())

ggplot(pagedata, aes(x='Date', y='Total Reach'))

ggplot(pagedata, aes(x = 'Date', y = x, group = metric)) + geom_line(aes(color = metric)) + 
  scale_x_date(breaks = "years", labels = date_format("%Y")) + scale_y_continuous("Number") +
  theme_bw() + theme(axis.title.x = element_blank())

# Testing -----------------------------------------------------------------

## Facebook Insights Test
#count <- 0

#repeat
#{
#  if (count < 100){
#   getInsights(object_id=postdata$postid[post], token=ftoken, metric=postmetrics[pmetric], period=period)
#    print(count)
#    count = count + 1
#  } 
#}
