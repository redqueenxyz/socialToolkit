library(twitteR)

setup_twitter_oauth(consumer_key = "Um3RcW1Xx3dmr2qJNvEWFTNyo", consumer_secret = "awqqZwm48COOlUcAGsBiwJa5eNMVs7ToVmGS9GQ4s2PDPlaLFV")

#loop through users, get description

users <- plcTweeters$V1
descriptions <- c()
#length(users)

for (user in 1:length(users)) {
  try(name <- getUser(users[user]))
  print(name)
  descriptions[user] <- name$description
}



for (tweet in 1:length(tweets))

user <- getUser('geoffjentry')
user$description