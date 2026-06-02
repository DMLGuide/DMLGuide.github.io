
# this is adapted from crossfit_with_embed.R
# the script prepares the data for the simplified website analysis

library(dplyr)
library(readr)
library(stringr)
library(reticulate)
library(keras3)
library(arrow)
library(ddml)


# ==============================================================================
# Set up
# ==============================================================================

data_root <- file.path("/Users/kahrens/Downloads/dataverse_files/Data/dube_monopsony")
data_path     <- file.path(data_root, "Data/")

outfile <- "/Users/kahrens/MyProjects/JEL/website/_dube_monopsony/data/monopsony_blog.rds"

# ==============================================================================
# Load data
# ==============================================================================

print("load & prepare data...")
ipeirotis_cleaned <- read_delim(paste0(data_path,"Monopsony_cleaned.csv"),delim=";") 
ipeirotis_cleaned <- ipeirotis_cleaned |> 
    group_by(requester_id) |>
    mutate(req_mean_rewards = mean(reward,na.rm=TRUE),
           req_mean_dur = mean(duration,na.rm=TRUE)) |>
    ungroup()

## add Gadiraju categories
gadiraju <- read_csv(paste0(data_path,"gadiraju_categories_ipeirotis.csv"))
gad_controls <- colnames(gadiraju)[-1]
ipeirotis_cleaned <- left_join(ipeirotis_cleaned,gadiraju,by="group_id")

## add additional columns
ipeirotis_cleaned_all <- read_delim(paste0(data_path,"Monopsony_cleaned_all.csv"),delim=";") 
additional_cols <- colnames(ipeirotis_cleaned_all)[!colnames(ipeirotis_cleaned_all) %in% colnames(ipeirotis_cleaned)]
ipeirotis_cleaned <- left_join(ipeirotis_cleaned,ipeirotis_cleaned_all[,c("group_id",additional_cols)],by="group_id")

# regular expression controls
regular_controls <- colnames(ipeirotis_cleaned_all)[str_starts(colnames(ipeirotis_cleaned_all), c("kw_|desc_|title_"))]

# handcoded controls
num_controls <- c("time_allotted",
        "first_hits",
        "last_hits",
        "max_hits",
        "avg_hitrate",
        "avg_hits_completed",
        "med_hits_completed",
        "min_hits_completed",
        "max_hits_completed",
        "num_zeros",
        "req_mean_rewards",
        "req_mean_dur",
        "title_len",
        "desc_len",
        "num_keywords",
        "title_words",
        "desc_words",
        "minutes_title",
        "minutes_kw",
        "qual_len",
        "num_quals",
        "custom_granted",
        "any_loc",
        "us_only",
        "appr_rate_gt",
        "appr_num_gt"
        )      
regular_controls <- regular_controls[!(regular_controls %in% num_controls)]

Xnumfeats <- ipeirotis_cleaned[,unique(c("group_id","requester_id",
                                          "log_reward","log_duration",
                                          num_controls,regular_controls,gad_controls))]  

## deal with NAs
# only few non-missing values; not worth imputing properly
vars_with_na <-   c("avg_hitrate", "avg_hits_completed", "med_hits_completed",  "min_hits_completed", "max_hits_completed")
Xnumfeats <- Xnumfeats |>
     mutate(across(all_of(vars_with_na),
               ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))

winsorize <- function(x, prob = 0.01, na.rm = TRUE,
                 top=TRUE,bottom=FALSE
) {
     # compute quantile cutoffs
     cuts <- quantile(x, probs = c(prob,1-prob), na.rm = na.rm)
     # cap at lower and upper bounds
     if (bottom) {
          x[x < cuts[1]] <- cuts[1]
     }
     if (top) {
          x[x > cuts[2]] <- cuts[2]
     }
     x
}

# log-transform continuous features and create dummies for certain features
Xnumfeats <- Xnumfeats |>
     mutate(
          time_allotted=log(time_allotted+1),
          first_hits=log(first_hits+1), 
          last_hits=1*(last_hits>0), # almost always zero
          max_hits=log(max_hits+1),
          avg_hitrate=log(avg_hitrate+1),
          avg_hits_completed=log(avg_hits_completed+1),
          med_hits_completed=log(med_hits_completed+1),
          min_hits_completed=log(min_hits_completed+1),
          max_hits_completed=log(max_hits_completed+1),
          max_hits=winsorize(max_hits, prob=0.01, top=TRUE, bottom=FALSE),
          avg_hitrate=winsorize(avg_hitrate, prob=0.01, top=TRUE, bottom=FALSE),
          avg_hits_completed=winsorize(avg_hits_completed, prob=0.01, top=TRUE, bottom=FALSE),
          med_hits_completed=winsorize(med_hits_completed, prob=0.01, top=TRUE, bottom=FALSE),
          min_hits_completed=winsorize(min_hits_completed, prob=0.01, top=TRUE, bottom=FALSE),
          max_hits_completed=winsorize(max_hits_completed, prob=0.01, top=TRUE, bottom=FALSE),
          num_zeros=log(num_zeros+1),
          num_zeros=winsorize(num_zeros, prob=0.01, top=TRUE, bottom=FALSE),
          req_mean_rewards=log(req_mean_rewards+1),
          req_mean_dur=log(req_mean_dur+1),
          title_len=log(title_len+1),
          desc_len=log(desc_len+1),
          num_keywords=log(num_keywords+1),
          title_words=log(title_words+1),
          desc_words=log(desc_words+1),
          minutes_title0=1*(minutes_title==0),
          minutes_title10=1*(minutes_title>0 & minutes_title<=10),
          minutes_title10p=1*(minutes_title>10),
          minutes_kw=1*(minutes_kw>0),
          qual_len0=1*(qual_len==0),
          qual_len100=1*(qual_len>0 & qual_len <= 100),
          qual_len100p=1*(qual_len>100),
          num_quals0=1*(num_quals==0),
          num_quals1t3=1*(num_quals>0 & num_quals<=3),
          num_quals4p=1*(num_quals>=4),
          appr_rate_gtm1=1*(appr_rate_gt==-1),
          appr_rate_gt90=1*(appr_rate_gt>=0 & appr_rate_gt<=90),
          appr_rate_gt100=1*(appr_rate_gt>90),
          appr_num_gtm1=1*(appr_num_gt==-1),
          appr_num_gt100=1*(appr_num_gt>=0 & appr_num_gt<100),
          appr_num_gt1000=1*(appr_num_gt>=100 & appr_num_gt<1000),
          appr_num_gt1000p=1*(appr_num_gt>=1000)
     )
Xnumfeats <- Xnumfeats |>
     dplyr::select(
          -minutes_title,
          -qual_len,
          -num_quals,
          -appr_rate_gt,
          -appr_num_gt
     )
Xnumfeats <- Xnumfeats |>
     mutate(across(all_of(regular_controls),~as.integer(.>0)))
Xnumfeats <- Xnumfeats |>
     mutate(across(all_of(gad_controls),~as.integer(.>0)))

saveRDS(Xnumfeats,outfile)