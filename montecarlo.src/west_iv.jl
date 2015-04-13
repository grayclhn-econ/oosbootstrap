# General code to execute the Monte Carlo simulations for the paper.
# Copyright 2015 Gray Calhoun

outputfile = ARGS[1]
codezfile = ARGS[2]
configfile = ARGS[3]

# The next lines define the parameters of the monte carlo exercise,
# including `ncore`, the number of processors to use for the
# calculations, start the additional processors, and then define the
# parameters again on each of the individual processors. (Everything
# in `configfile` is wrapped in an `@everywhere` macro.)
include(configfile)
addprocs(ncore - 1)
include(configfile) # define variables on other processors
include(codezfile) # define estimators, etc.

# These variables are defined in `configfile`
@everywhere eachmc(x) = allmcs(x, nboot, Ps, Rs, α)
mcres = mean(pmap(eachmc, fill(integer(nsims / nprocs()), nprocs())))

stats = ["Naive", "CS07", "Full", "Ours"]
f = open(outputfile, "w")
write(f, "R,P,Method,Size\n")
for r in 1:length(Rs), p in 1:length(Ps), m in 1:length(stats)
    write(f, "$(Rs[r]),$(Ps[p]),$(stats[m]),$(mcres[p,r,m])\n")
end
close(f)
