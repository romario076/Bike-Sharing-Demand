
library(ggplot2)
library(corrplot)
library(gbm)
#Load train data
train<- read.csv("train.csv")

#Use plot to see how data behaves
par(mfrow=c(2,3))
par(mar = c(7, 5, 2, 2) )
boxplot(train[,-(1:5)], las=2, col="darkseagreen4",title="general")
boxplot(train$count~train$weather, xlab="weather", ylab="Count", col="steelblue")
boxplot(train$count~train$holiday, xlab="Holiday", ylab="Count", col="steelblue")
boxplot(train$count~train$workingday, xlab="Workingday", ylab="Count", col="steelblue")
boxplot(train$count~train$season, xlab="season", ylab="Count", col="steelblue")
dev.off()

# For cathegorical variables plots
g1<-ggplot(train,aes(count, color=factor(season),fill=factor(season)))+
  geom_density(alpha = 0.2)+ggtitle("Season-count")
g2<-ggplot(train,aes(count, color=factor(weather),fill=factor(weather)))+
  geom_density(alpha = 0.2)+ggtitle("Weather-count")
g3<-ggplot(train,aes(count, color=factor(holiday),fill=factor(holiday)))+
  geom_density(alpha = 0.2)+ggtitle("Holiday-count")
require(gridExtra)
grid.arrange(g1, g2,g3, ncol=2,nrow=2)

# For numeric variables
g4<-ggplot(train,aes(count, temp))+geom_point(alpha = 0.4)+ggtitle("temp-count")
g5<-ggplot(train,aes(count, atemp))+geom_point(alpha = 0.4)+ggtitle("atemp-count")
g6<-ggplot(train,aes(count, humidity))+geom_point(alpha = 0.4)+ggtitle("Humidity-count")
g7<-ggplot(train,aes(count, windspeed))+geom_point(alpha = 0.4)+ggtitle("Windspeed-count")
grid.arrange(g4,g5,g6,g7, ncol=2,nrow=2)

# How change count with time
train$datetime <- as.POSIXct(train$datetime, format="%Y-%m-%d %H:%M:%S")
plot(train$datetime, train$count, type="l", lwd=0.7,main="Count of Bike Rentals")

#Correlation matrix
cor<- train[,c(2,3,4,5,6,7,8,9,12)]
m<- cor(cor)
corrplot(m, method = "number")

train$season <- factor(train$season, c(1,2,3,4), ordered=FALSE)
 train$holiday <- factor(train$holiday, c(0,1), ordered=FALSE)
 train$workingday <- factor(train$workingday, c(0,1), ordered=FALSE)
 train$weather <- factor(train$weather, c(4,3,2,1), ordered=TRUE)

#Regression, R-squared=32%
fit<- lm(count~., train[,-c(10,11)])
summary(fit)


test <- read.csv("test.csv")

# gbm -base model ####
genmod<-gbm(train$count~.
                   ,data=train[,-c(1,9,10,11)] ## registered,casual,count columns
                   ,var.monotone=NULL # which vars go up or down with target
                   ,distribution="gaussian"
                   ,n.trees=2000
                   ,shrinkage=0.01
                   ,interaction.depth=3
                   ,bag.fraction = 0.5
                   ,train.fraction = 1
                   ,n.minobsinnode = 10
                   ,cv.folds = 10
                   ,keep.data=TRUE
                   ,verbose=TRUE)
best.iter <- gbm.perf(genmod,method="cv")
print(pretty.gbm.tree(genmod, best.iter))
summary(genmod)
pred.test <- predict(genmod, test[,-c(1,9)], best.iter, type="response")
pred.test[pred.test<0]<- 0
out<- data.frame(datetime=test[,1], count=pred.test)
write.csv(out, file="resultsN.csv", quote=FALSE, row.names=FALSE)


#md<- train(count~., data=train[,c(-1,-10,-11)], method="gbm", verbose=F)
#test$season <- factor(test$season, c(1,2,3,4), ordered=FALSE)
#test$holiday <- factor(test$holiday, c(0,1), ordered=FALSE)
#test$workingday <- factor(test$workingday, c(0,1), ordered=FALSE)
#test$weather <- factor(test$weather, c(4,3,2,1), ordered=TRUE)
#pred<- predict(md, test[,-1])
#out<- data.frame(datetime=test[,1], count=round(pred))
