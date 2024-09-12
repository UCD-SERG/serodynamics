library(readxl)
library(dplyr)

## Load compiled shigella dataset
df <- read_excel("draft/3.8.2024 Compiled Shigella datav2.xlsx", 
                 sheet = "Compiled")

# select longitudinal dataset from complied dataset

df_sosar<-df%>%filter(study_name=="SOSAR")


# Add 'visit_num' variable into this dataset

df_sosar_visit<-df_sosar%>%group_by(sid, isotype_name) %>% 
  arrange(timepoint) %>%                          # Sort data by visit within each group
  mutate(visit_num = rank(timepoint, ties.method = "first")) %>%
  ungroup()

write_csv(df_sosar_visit, "df_sosar_visit.csv")

# split the data by isotype

df_sosar_IgA<-df_sosar%>%filter(isotype_name=="IgA")## it doesn't matter with choosing isotype


# Count unique values of CaseID
unique_count <- length(unique(df_sosar$sid))

# Print the count 
print(unique_count)##  48 unique sample id with 218 observations

df_test<-df_sosar_IgA%>%select(sid,timepoint)

df_test<- df_test %>%arrange(sid) ## 218 observations 

###############################################################################
## Load actual day collection dataset
df2<-read_excel("Actual day of collection.xlsx", sheet ="Actual day")

# Count unique values of CaseID
unique_count2 <- length(unique(df2$CaseID))

# Print the count
print(unique_count2)## 139 unique sample id with 428 observations

############################################################################
## subset of df2 based on df sid, so we can compare observations

# Create a vector of unique sid values from df_test
unique_sids <- unique(df_test$sid)

# Filter df2 to include only rows where CaseID is in the unique_sids vector
filtered_df2 <- df2 %>%
  filter(CaseID %in% unique_sids)%>%select(CaseID,`Actual day`)

print(filtered_df2) ## 229 observations
