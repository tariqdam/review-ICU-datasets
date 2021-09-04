---
title: "MIMIC-IV"
author: "Christopher M. Sauer"
date: "2/1/2021"
output: html_document
---

```{r}
library(dplyr)
library(tidyr)
mort=read.csv (file='C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_mort.csv')
death= read.csv (file='C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_deathdata.csv')
mort2 <- full_join(x = mort, y=death )
mort2 <- mort2[order(mort$subject_id, abs(mort$stay_id) ), ] #sort by id and abs(value)
mort3=mort2[ !duplicated(mort2$subject_id), ] 
mort4 <- mort3 %>%  mutate(ICUdth = ifelse(outtime> deathtime, 0, 1))  
mort4$ICUdth[is.na(mort3$deathtime)] <- 0
mean(mort4$ICUdth)*100

#mortality since admission in minutes 
mort3$deathtime <- strptime(mort3$deathtime, "%m/%d/%Y %H:%M") 
mort3$intime <- strptime(mort3$intime, "%Y-%m-%d %H:%M:%S")
mort3$surv_time<-mort3$deathtime-mort3$intime

#28 day mortality
mort3 <- mort3 %>%  mutate(mort28d = ifelse(surv_time> 40320, 0, 1))  
mort3$mort28d[is.na(mort3$mort28d)] <- 0
mean(mort3$mort28d)*100

#28 day mortality
mort3 <- mort3 %>%  mutate(mort90d = ifelse(surv_time> 129600, 0, 1))  
mort3$mort90d[is.na(mort3$mort90d)] <- 0
mean(mort3$mort90d)*100

```

``` {r}
#Comorbidities

comorb  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_comorb.csv")
sum(is.na(comorb$icd_code))

comorb2=comorb[ !duplicated(comorb$hadm_id), ] 
--> 58314 hadm 
Total hadm = 69619
(58314/69619*100)
```

```{r}
#Type admission
adm  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_adm.csv")
table(adm$admission_type)
summary(adm$admission_type)
summary(adm$first_careunit)
table(adm$first_careunit)
```

```{r}
#Any vasopressor 

vaso.1  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_vaso.csv")

vaso.2  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_phen_epi.csv")
vaso.2 <- vaso.2 %>%  mutate(stay_id =(coalesce(stay_id, stay_id_1)))
vaso.2 = vaso.2[, c(1,2,4)]
vaso.2 <- vaso.2 %>%  mutate(f0_ =(coalesce(f0_, f1_)))
vaso.2 = vaso.2[, c(1,2)]

vaso.3  = read.csv(file = "C:/Users/chris/OneDrive/Research/Review ICU data sets/mimic_dop_dob.csv")
vaso.3 <- vaso.3 %>%  mutate(stay_id =(coalesce(stay_id, stay_id_1)))
vaso.3 = vaso.3[, c(1,2,4)]
vaso.3 <- vaso.3 %>%  mutate(f0_ =(coalesce(dob, dop)))
vaso.3 = vaso.3[, c(1,4)]

vaso_comb <- rbind(vaso.1, vaso.2, vaso.3)
nrow(vaso_comb)
```

```{r}
#Duration of stay ICU in minnutes 
los=read.csv (file='C:/Users/chris/OneDrive/Research/Review ICU data sets/Data extractions Chris/mimic_mort.csv')
los2 <- los[order(los$subject_id, abs(los$stay_id) ), ] #sort by id and abs(value)
los3=los2

los3$outtime <- strptime(los3$outtime, "%Y-%m-%d %H:%M:%S") 
los3$intime <- strptime(los3$intime, "%Y-%m-%d %H:%M:%S")
los3$los2 <-difftime(los3$outtime, los3$intime, units = "hours")
los3$los2 <- as.numeric(los3$los2)
sum(los3$los2, na.rm = TRUE)

``` 
