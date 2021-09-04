---
title: "AmsterdamUMCdb"
author: "Christopher M. Sauer"
date: "2/1/2021"
output: html_document
---

```{r}
library(dplyr)
library(tidyr)
mort=read.csv (file='C:/Users/chris/OneDrive/Research/Review ICU data sets/amsterdam_basics.csv')
mort <- mort %>% mutate(dateofdeath = ifelse(dateofdeath== "NULL", NA, dateofdeath))

#median age 
table(mort$agegroup)

#first stay mortality 
mort2 <- mort[order(mort$patientid, abs(mort$admissionid) ), ] #sort by id and reverse of abs(value)
mort3=mort2[ !duplicated(mort2$patientid), ] 


#ICU mort
mort3 <- mort3 %>%  mutate(ICUdth = ifelse(dischargedat> dateofdeath, 0, 1))
mort3$ICUdth[is.na(mort3$ICUdth)] <- 0
mean(mort3$ICUdth)*100

#mort 28 days
mort3 <- mort3 %>%  mutate(mort28 = ifelse(dateofdeath<= 2419200000, 1, 0))
mort3$mort28[is.na(mort3$mort28)] <- 0
mean(mort3$mort28)*100

#mort 90 days
mort3 <- mort3 %>%  mutate(mort90 = ifelse(dateofdeath<= 7776000000, 1, 0))
mort3$mort90[is.na(mort3$mort90)] <- 0
mean(mort3$mort90)*100

#LOS
median(mort3$dischargedat/86400000)
quantile(mort3$dischargedat/86400000)

#Specialty 
table(mort3$specialty)
nrow(mort3)
##Surgical: 7035+166+914+312+400+318+17+2136+13+4+173+24+1055+167+1156+15 --> 13905
##Medical: 1219+211+1114+374+147+296+658+68+3 --> 4090
##Other: 52+959 --> 1011 
## Unknown 1103

#Urgency
table(mort3$urgency)

#Sum of Length of stay in hours
sum(mort3$dischargedat-mort3$admittedat)/3600000
```

```{r}
vaso.1  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/amsterdam_vasopressor.csv", header = FALSE, sep = ';')
colnames(vaso.1) <- c("admission_id", "item", "value", "unit", "measuredat", "subject_id")
vaso.2=vaso.1[ !duplicated(vaso.1$admission_id), ]
```