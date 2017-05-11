## Facebook Data Aggregator ####
## By Vivek Menon ##############
## v.1.0.0 #####################


# Setup -------------------------------------------------------------------

# Required Packages for dataframes, forecasting, and graphical visualization
library(ggplot2, zoo, forecast)
library(Rfacebook)
library(twitteR)

library(devtools)

install_github("pablobarbera/Rfacebook/Rfacebook")



## Check full documentation: http://cran.r-project.org/web/packages/Rfacebook/Rfacebook.pdf
## SearchFacebook

id <- "268482149858366"
secret <- "ef975e63a461b63b99796081ffd94388"

fb_oauth <- fbOAuth(app_id=id, app_secret=secret)
save(fb_oauth, file="fb_oauth")
load("fb_oath")

load("fb_oauth")
me <- getUsers("me", token=fb_oauth)
me$username

# Use token from Facebook Graph API 
token <- "CAACEdEose0cBAIJVgn9iGH21Q69dsxKNZCr6Mrx57CKJWc3BclFrbhO2j7M6PbJMv0M3g5WVU1yhwtP0rhyVpq9kvR3br2RwcRg0DHCL8ZANCnbiaXVKy9iixWjHU68UZA14zHZAZBrqJtuLKEP4ZBJGNYReQsT94Cn9xyeD0qnyF3EuEBQ6Rrc6SyZAO26d9kZD"
users <- getUsers("me", token=token)

# Initial -----------------------------------------------------------------



# Setup working directy; where are all the files?
getwd()
setwd() # Modify setwd as necessary with absolute path to directory. 

print(getwd())
mdir = "~/Desktop/2015/"
setwd(mdir)

# For every Folder in directory
for (file in 1:length(list.files())) {
  #print(file)
  # Print Folder Name
  print(list.files()[file])
  #setwd(paste(mdir,list.files()[file],sep=""))
  
  # Reset top Folder
  #setwd(mdir)
}

list.files()

# Processing --------------------------------------------------------------




# Outputs -----------------------------------------------------------------




