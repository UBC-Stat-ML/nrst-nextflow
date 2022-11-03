library(dplyr)
library(tidyr)

# search for csv files, process them, and save result
tsvs = list.files(pattern = '^NRSTExp_\\d+_\\d+.tsv$')
fns  = substr(tsvs, 1, nchar(tsvs)-4)
dta  = data.frame()
for(i in seq_along(fns)){
  #i=1
  rawmeta     = read.delim(tsvs[i], header = FALSE)
  meta        = as.data.frame(t(rawmeta[,-1]))
  names(meta) = rawmeta[, 1]
  newdta      = read.csv(paste0(fns[i], ".csv.gz"))
  dta         = bind_rows(dta, crossing(meta, newdta))
}
write.csv(
  dta, 
  paste0("NRSTExp_",as.integer(trunc(as.numeric(Sys.time()))),".csv"),
  row.names = FALSE
)
