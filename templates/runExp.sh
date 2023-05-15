JULIA_DEBUG=NRST julia --project=$jlenv \
    -t ${task.cpus} \
    -e "using NRSTExp; dispatch()" \
    sam=$sampler  \
    exp=$exper  \
    mod=$model  \
    fun=$fun    \
    cor=$maxcor \
    gam=$gamma  \
    xpl=$xpl    \
    xps=$xps    \
    seed=$seed

