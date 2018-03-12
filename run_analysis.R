###########################################
## Getting and Cleaning Data Course Project
###########################################

###########################################
## zip file was downloaded and extracted
###########################################

###########################################
## Reading data into data frames
###########################################

## test data
test_df <- read.table("./UCI HAR Dataset/test/X_test.txt", header = FALSE)
test_labels<-read.table("./UCI HAR Dataset/test/y_test.txt", header = FALSE)
test_subj<-read.table("./UCI HAR Dataset/test/subject_test.txt", header = FALSE)

## train data
train_df <- read.table("./UCI HAR Dataset/train/X_train.txt", header = FALSE)
train_labels<-read.table("./UCI HAR Dataset/train/y_train.txt", header = FALSE)
train_subj<-read.table("./UCI HAR Dataset/train/subject_train.txt", header = FALSE)

## additional data
features_df <- read.table("./UCI HAR Dataset/features.txt", header = FALSE)
activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", header = FALSE)

## changing some variable names
names(test_labels)<-"activity"
names(test_subj)<-"subject"
names(train_labels)<-"activity"
names(train_subj)<-"subject"
names(test_df)<-as.character(features_df$V2)
names(train_df)<-as.character(features_df$V2)

## complete data
complete_test_df<-cbind(test_subj,test_labels,test_df)
complete_train_df<-cbind(train_subj,train_labels,train_df)
complete_df<-rbind(complete_train_df,complete_test_df)

## Makes every column name unique
for(i in 1:563){
        for(j in 1:563){
                if(names(complete_df)[j]==names(complete_df)[i] & i!=j){
                        names(complete_df)[j]<-paste0(names(complete_df)[j],".",as.character(j))
                }
        }
}

## this new data.frame contains only those columns in complete_df 
## that contain mean or std
library(dplyr)
ms_complete_df<-select(complete_df,"subject", "activity",contains("mean()"),contains("std()"))

## change activities to factor, then rename
ms_complete_df$activity<-factor(ms_complete_df$activity)
ms_complete_df$activity <- factor(ms_complete_df$activity, levels=1:6,labels=activity_labels$V2) 

## Tidying the data set
library(stringr)
library(tidyr)
tidyData<- ms_complete_df %>% gather(measurements,value,-subject,-activity)
tidyData<- tidyData %>% separate(measurements, c("domain","measurement"),1)
tidyData$domain<-factor(tidyData$domain)
tidyData$domain <- factor(tidyData$domain, levels=c("t","f"),labels=c("time","frequency"))
meanLoc<-grepl("mean",tidyData$measurement,fixed = TRUE)
meanStdValue<-vector("character",length = 679734)
for(i in 1:679734){
        if(meanLoc[i]==TRUE){
                meanStdValue[i]<-"mean"
        }else{
                meanStdValue[i]<-"standard deviation"
        }
}
tidyData<-mutate(tidyData,statistic=meanStdValue)
tidyData$statistic<-factor(tidyData$statistic)
tidyData<-select(tidyData, subject, activity, domain, statistic, measurement, value)
tidyData$measurement<-sub("mean","",gsub("[[:punct:]]","",tidyData$measurement))
tidyData$measurement<-sub("std","",tidyData$measurement,fixed = TRUE)

## group data by activity and subject (as well as the new variables - this makes sure that every variable is involved in the average calculation)
tidyData_grouped <- tidyData %>% group_by(activity,subject,domain,statistic,measurement)

## computes mean by group and renames variables appropriately
tidyData_grouped_ave<-tidyData_grouped %>% summarize(mean=mean(value))
tidyData_grouped_ave<-tidyData_grouped_ave %>% spread(measurement,mean)
names(tidyData_grouped_ave)[5:27]<-paste0("ave",names(tidyData_grouped_ave)[5:27])

## Writes the data set 'tidyData_grouped_ave' to the text file 'tidyData.txt'
write.table(tidyData_grouped_ave, file = "tidyData.txt", row.names = FALSE)
