@everywhere begin ## Define functions and variables on each processor
## Generate data for Monte Carlo based on West's (1996) IV simulation
function makedata!(y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64})
    # We're storing the initial errors v in the vector y to save
    # memory. The code matches the mathematics better using v as an
    # alias for y.
    v = y
    randn!(v); randn!(w); randn!(z)
    for i in 1:length(y)
        w[i,1] = z[i,1] + v[i]
        w[i,2] = z[i,2] + v[i]
        y[i] = w[i,1] + w[i,2] + v[i] # This line writes over v[i] as well.
    end
end

## oosstat! constructs the OOS test statistic corresponding to example
## 5.2 West's 1996 Econometrica paper. It also accomodates a data reordering
## a la the block bootstrap, which is what my paper proposes.
##
## βhat - An array that stores the recursive parameter estimates after the
##        function exectes. This array is overwritten.
## f -    The vector that will hold the out-of-sample statistics; this vector
##        is overwritten by the function.
## ZW_t - preallocated storage for the recursive window matrices Z[i,1:t]'*W[i,1:t];
##        this array is written over by the function (2 × 2 × k)
## ZY_t - preallocated storage for the recursive window vector Z[i,1:t]'*Y[1:t];
##        this matrix is written over by the function, (2 × k)
## l_t  - preallocated storage for the period t forecast loss, k-vector.
## y -    Data: the target varable, n-vector.
## w -    A matrix with the predictors; (n × k) each column corresponds to
##        a different forecasting model. The models will be estimated with IV
## z -    A matrix with the instruments for each model (n × k).
## bootindex - A vector of the bootstrap-generated index. Defaults to no bootstrap.

function oosstat!(βhat::Array{Float64,3}, f::Vector{Float64},
                  ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64}, l_t::Vector{Float64},
                  y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64},
                  bootindex::Vector{Int})
    T = length(y)
    R = T - length(f)
    return oosstat_broken!(βhat, f, ZW_t, ZY_t, l_t, y, w, z,
                           bootindex[1:R], bootindex[(R+1):T])
end

function oosstat!(βhat::Array{Float64,3}, f::Vector{Float64},
                  ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64}, l_t::Vector{Float64},
                  y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64})
    return oosstat!(βhat, f, ZW_t, ZY_t, l_t, y, w, z, [1:length(y)])
end

## oosstat_broken! constructs the OOS test statistic corresponding to
## example 5.2 West's 1996 Econometrica paper, but allowing the first
## R and the remaining P observations to be indexed independently. It
## also accomodates a data reordering a la the block bootstrap, which
## is what my paper proposes. Note that `oosstat!` calls
## `oosstat_broken!` for its functionality, but the paper recommends
## calling `oosstat_broken!` directly using independent bootstraps
## over 1:R and R+1:T.
##
## βhat - An array that stores the recursive parameter estimates after the
##        function exectes. This array is overwritten.
## f -    The vector that will hold the out-of-sample statistics; this vector
##        is overwritten by the function.
## ZW_t - preallocated storage for the recursive window matrices Z[i,1:t]'*W[i,1:t];
##        this array is written over by the function (2 × 2 × k)
## ZY_t - preallocated storage for the recursive window vector Z[i,1:t]'*Y[1:t];
##        this matrix is written over by the function, (2 × k)
## l_t  - preallocated storage for the period t forecast loss, k-vector.
## y -    Data: the target varable, n-vector.
## w -    A matrix with the predictors; (n × k) each column corresponds to
##        a different forecasting model. The models will be estimated with IV
## z -    A matrix with the instruments for each model (n × k).
## bootindexR - A vector of the bootstrap-generated index over the first R observations.
## bootindexP - A vector of the bootstrap-generated index over the last P observations.
function oosstat_broken!(βhat::Array{Float64,3}, f::Vector{Float64},
                  ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64}, l_t::Vector{Float64},
                  y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64},
                  bootindexR::Vector{Int}, bootindexP::Vector{Int})
    R = length(bootindexR)
    _,_,k = size(ZW_t)
    # Initialize ZW_t and ZY_t
    for i in 1:k
        ZW_t[1, 1, i] = R
        ZW_t[1, 2, i] = sum(w[bootindexR,i])
        ZW_t[2, 1, i] = sum(z[bootindexR,i])
        ZW_t[2, 2, i] = sum(w[bootindexR, i] .* z[bootindexR, i])
        ZY_t[1, i] = sum(y[bootindexR])
        ZY_t[2, i] = sum(y[bootindexR] .* z[bootindexR, i])
    end
    # Update with next observation and produce forecasts
    for t = 1:(length(y) - R)
        boot_t = bootindexP[t]
        for i in 1:k
            # Construct the coefficient estimator from its previously
            # calculated components and forecast
            βhat[:,t,i] = ZW_t[:,:,i] \ ZY_t[:,i]
            l_t[i] = (y[boot_t] - (βhat[1,t,i] + βhat[2,t,i] * w[boot_t,i]))^2
            # Update estimates with the current observation.
            ZW_t[1,1,i] += 1.
            ZW_t[1,2,i] += w[boot_t,i]
            ZW_t[2,1,i] += z[boot_t,i]
            ZW_t[2,2,i] += w[boot_t,i] * z[boot_t,i]
            ZY_t[1,i] += y[boot_t]
            ZY_t[2,i] += z[boot_t,i] * y[boot_t]
        end
        f[t] = l_t[1] - l_t[2]
    end
    return mean(f)
end

## oosnaive constructs bootstrapped OOS test statistic that one
## gets by just bootstrapping the observed out-of-sample loss differences.
##
## f -  A vector holding the original out-of-sample statistics.
## bootindex - A vector of the bootstrap-generated index.

function oosnaive(f::Vector{Float64}, bootindex::Vector{Int})
    P = length(f)
    bootstat = 0.0
    for t in bootindex
        bootstat += f[t] / P
    end
    return bootstat
end

# newbootmean! calculates the centering term for our bootstrap using
# West's OOS statistic. The arguments are simliar to those in oosstat!
function newbootmean!(ZW::Array{Float64,3}, ZY::Matrix{Float64}, l::Vector{Float64},
                      y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64})
    _,k = size(z)
    for i in 1:k
        ZW[1,1,i] = 1.
        ZW[1,2,i] = mean(w[:,i])
        ZW[2,1,i] = mean(z[:,i])
        ZW[2,2,i] = mean(z[:,i] .* w[:,i])
        ZY[1,i] = mean(y)
        ZY[2,i] = mean(y .* z)
        coef = ZW[:,:,i] \ ZY[:,i]
        l[i] = mean((y - (coef[1] + coef[2] * w[:,i])).^2)
    end
    l[1] - l[2]
end

## runmc! runs the West (1996)-based Monte Carlo for a particular value of P, R, and α.
## - oosstat: preallocated vector that stores the oos test statistics for
##   each run. The length of this array is the number of simulations.
## - oostest: preallocated array that contains the result of each oos
##   bootstrap based test.
## - nboot: number of bootstrap replications (Integer).
## - P, R: number of oos and number of in-sample observations (both Integers).
## - α: nominal test size.

function runmc!(oosstat::Vector{Float64}, oostest::BitArray, nboot, P, R, α)
    n = P + R
    y = Array(Float64, n)
    w = Array(Float64, n, 2)
    z = Array(Float64, n, 2)
    ZW = Array(Float64, 2, 2, 2)
    ZY = Array(Float64, 2, 2)
    l = Array(Float64, 2)
    yboot = similar(y)
    wboot = similar(w)
    zboot = similar(z)
    f = Array(Float64,  P)
    βhat = Array(Float64, 2, P, 2)
    fullindex = Array(Int, n)
    initindex = Array(Int, R)
    naiveindex = Array(Int, P)
    oosboot = Array(Float64, 2, nboot)
    bootmean = Array(Float64, 2)
    for i in 1:length(oosstat)
        makedata!(y, w, z)
        oosstat[i] = oosstat!(βhat, f, ZW, ZY, l, y, w, z)
        ## Do "non-destructive" bootstraps
        for j in 1:nboot
            rand!(1:P, naiveindex)
            oosboot[1,j] = oosnaive(f, naiveindex)
        end
        bootmean[1] = mean(oosboot[1,:])
        ## Destructive bootstrap (overwrites f and βhat as well as ZW and ZY)
        for j in 1:nboot
            rand!(1:n, fullindex)
            oosboot[2,j] = oosstat!(βhat, f, ZW, ZY, l, y, w, z, fullindex)
        end
        bootmean[2] = mean(oosboot[2,:])
        for j in 1:length(bootmean)
            bootcrit = quantile(vec(oosboot[j,:]), [α/2, 1 - α/2]) - bootmean[j]
            oostest[j,i] = oosstat[i] < bootcrit[1] || oosstat[i] > bootcrit[2]
        end
    end
end

## allmcs! runs the West (1996)-based Monte Carlo for several
## different values of P and R; it basically wraps `runmc!`
## - nsim: number of simulations to run
## - nboot: number of bootstrap replications (Integer).
## - Ps, Rs: vectors with different values of P and R
## - α: nominal test size

function allmcs(nsim, nboot, Ps, Rs, α)
    results = Array(Float64, length(Ps), length(Rs), 2)
    mcstat = Array(Float64, nsim)
    mctest = BitArray(2, nsim)
    for r in 1:length(Rs), p in 1:length(Ps)
        runmc!(mcstat, mctest, nboot, Ps[p], Rs[r], α)
        results[p,r,:] = mean(mctest, 2)
    end
    return results
end
end
