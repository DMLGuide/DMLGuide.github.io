library("ddml")
library("haven")
library("estimatr")
library("dplyr")

dta <- read_dta("http://fmwww.bc.edu/repec/bocode/j/jtpa.dta")
dta <- as.data.frame(dta)
dta <- subset(dta,sex==1)

controls <- c("hsorged","black","hispanic","married","wkless13","class_tr",
              "ojt_jsa","age2225","age2629","age3035","age3644","age4554","f2sms")

ols_fm <- as.formula(paste("earnings~training+",paste(controls,collapse="+")))
iv_fm <- as.formula(paste("earnings~training+",paste(controls,collapse="+"),
                          "|assignmt+",paste(controls,collapse="+")))


lm_robust(ols_fm,data=dta)  
iv_robust(iv_fm,data=dta)  


y <- dta$earnings
D <- dta$training
Z <- dta$assignmt
X <- as.matrix(dta[,controls])


learners_multiple <- list(list(fun = ols),
                          list(fun = mdl_glmnet),
                          list(fun = mdl_glmnet,
                               args = list(alpha = 0))
                          )



fit1 <- ddml_plm(y,
         D,
         X,
         learners=list(what=mdl_glmnet
                       ))
summary(fit1)

fit1 <- ddml_plm(y,
                 D,
                 X,
                 learners=learners_multiple,
                 shortstack = TRUE
                 )
summary(fit1)

fit1 <- ddml_late(y,
                 D,
                 Z,
                 X,
                 learners=learners_multiple,
                 ensemble_type = "nnls",
                 custom_ensemble_weights = diag(length(learners_multiple)),
                 shortstack = TRUE
)
summary(fit1)
fit1$weights

