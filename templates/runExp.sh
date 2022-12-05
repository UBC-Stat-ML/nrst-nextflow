JULIA_DEBUG=NRST julia --project=$jlenv -t 8 \
    -e "using NRSTExp; dispatch()" \
    exp=$exper  \
    mod=$model  \
    fun=$fun    \
    cor=$maxcor \
    gam=$gamma  \
    xps=$xps    \
    seed=$seed

