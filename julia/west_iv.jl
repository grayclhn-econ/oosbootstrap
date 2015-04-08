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

# oosstat! constructs the OOS test statistic corresponding to example
# 5.2 in his 1996 Econometrica paper
#
# f - the vector that will hold the out-of-sample statistics; this vector
#     is overwritten by the function.
# y - data: the target varable, n-vector
# w - a matrix with the predictors; (n × k) each column corresponds to
#     a different forecasting model. The models will be estimated with IV
# z - a matrix with the instruments for each model (n × k)
# ZW_t - preallocated storage for the recursive window matrices Z[i,1:t]'*W[i,1:t];
#        this array is written over by the function (2 × 2 × k)
# ZY_t - preallocated storage for the recursive window vector Z[i,1:t]'*Y[1:t];
#        this matrix is written over by the function, (2 × k)
# l_t  - preallocated storage for the period t forecast loss, k-vector
function oosstat!(βhat::Array{Float64,3}, f::Vector{Float64},
                  ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64}, l_t::Vector{Float64},
                  y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64})
    return oosstat!(βhat, f, ZW_t, ZY_t, l_t, y, w, z, [1:length(y)])
end

function oosstat!(βhat::Array{Float64,3}, f::Vector{Float64},
                  ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64}, l_t::Vector{Float64},
                  y::Vector{Float64}, w::Matrix{Float64}, z::Matrix{Float64},
                  bootindex::Vector{Int})
    R = length(y) - length(f)
    _,_,k = size(ZW_t)
    # Initialize ZW_t and ZY_t
    bootinit = bootindex[1:R]
    for i in 1:k
        ZW_t[1, 1, i] = R
        ZW_t[1, 2, i] = sum(w[bootinit,i])
        ZW_t[2, 1, i] = sum(z[bootinit,i])
        ZW_t[2, 2, i] = sum(w[bootinit, i] .* z[bootinit, i])
        ZY_t[1, i] = sum(y[bootinit])
        ZY_t[2, i] = sum(y[bootinit] .* z[bootinit, i])
    end
    # Update with next observation and produce forecasts
    for t = (R+1):length(y)
        boot_t = bootindex[t]
        for i in 1:k
            # Construct the coefficient estimator from its previously
            # calculated components and forecast
            βhat[:,t-R,i] = ZW_t[:,:,i] \ ZY_t[:,i]
            l_t[i] = (y[boot_t] - (βhat[1,t-R,i] + βhat[2,t-R,i] * w[boot_t,i]))^2
            t == length(y) && break
            # Update estimates with the current observation.
            ZW_t[1,1,i] += 1.
            ZW_t[1,2,i] += w[boot_t,i]
            ZW_t[2,1,i] += z[boot_t,i]
            ZW_t[2,2,i] += w[boot_t,i] * z[boot_t,i]
            ZY_t[1,i] += y[boot_t]
            ZY_t[2,i] += z[boot_t,i] * y[boot_t]
        end
        f[t-R] = l_t[1] - l_t[2]
    end
    return mean(f)
end

function oosnaive(f::Vector{Float64}, bootindex::Vector{Int})
    P = length(f)
    bootstat = 0.0
    for t in bootindex
        bootstat += f[t] / P
    end
    return bootstat
end

function ooscs07!(ZW_t::Array{Float64,3}, ZY_t::Matrix{Float64},
                  l_t::Vector{Float64}, βhat::Array{Float64,3},
                  y::Vector{Float64}, w::Matrix{Float64},
                  z::Matrix{Float64}, boot::Vector{Int})
    P = length(f)
    ## Intialize Z'W matrix
    _,_,k = size(ZW_t)
    for i in 1:k
        ZW_t[1, 1, i] = R
        ZW_t[1, 2, i] = sum(w[boot[1:R], i])
        ZW_t[2, 1, i] = sum(z[boot[1:R], i])
        ZW_t[2, 2, i] = sum(w[boot[1:R], i] .* z[boot[1:R], i])
    end
    fboot = 0.0
    for t = (R+1):length(y)
        for i in 1:2
            ## need βhat[t,:] to be the coefficients used to predict
            ## period t's y
            mAdj_it = mean(y - (βhat[1,t-R,i] + βhat[2,t-R,i] * w[:,i]))
            ZY_t[1,i] = sum(y[boot[1:(t-1)]] - mAdj_it)
            ZY_t[2,i] = (z[boot[1:(t-1)],i] '* (y[boot[1:(t-1)]] - mAdj_it))[1]
            βh_it = ZW_t[:,:,i] \ ZY_t[:,i]
            l_t[i] = ((y[boot[t]] - (βh_it[1] + βh_it[2] * w[t,i]))^2 -
                      mean((y - (βhat[1,t-R,i] + βhat[2,t-R,i] * w[:,i])).^2))
            ## Update Z'W matrix
            ZW_t[1,1,i] += 1.
            ZW_t[1,2,i] += w[boot[t],i]
            ZW_t[2,1,i] += z[boot[t],i]
            ZW_t[2,2,i] += w[boot[t],i] * z[boot[t],i]
        end
        fboot += (l_t[1] - l_t[2]) / P
    end
    return fboot
end

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
    myindex = Array(Int, n)
    naiveindex = Array(Int, P)
    oosboot = Array(Float64, 3, nboot)
    bootmean = Array(Float64, 3)
    for i in 1:length(oosstat)
        makedata!(y, w, z)
        oosstat[i] = oosstat!(βhat, f, ZW, ZY, l, y, w, z)
        ## Do "non-destructive" bootstraps (still overwrites some of
        ## the arguments, though)
        for j in 1:nboot
            rand!(1:P, naiveindex)
            oosboot[1,j] = oosnaive(f, naiveindex)
            rand!(1:n, myindex)
            oosboot[2,j] = ooscs07!(ZW, ZY, l, βhat, y, w, z, myindex)
        end
        bootmean[1] = mean(oosboot[1,:])
        bootmean[2] = 0 ## second bootstrap is centered inside ooscs07!
        ## Destructive bootstrap (overwrites f and βhat)
        for j in 1:nboot
            rand!(1:n, myindex)
            oosboot[3,j] = oosstat!(βhat, f, ZW, ZY, l, y, w, z, myindex)
        end
        bootmean[3] = mean(oosboot[3,:])
        for j in 1:3
            bootcrit = quantile(vec(oosboot[j,:]), [α/2, 1 - α/2]) - bootmean[j]
            oostest[j,i] = oosstat[i] < bootcrit[1] || oosstat[i] > bootcrit[2]
        end
    end
end

nsim =  3;
nboot = 19;
P =     120;
R =     240;
α =       0.1;
mcstat = Array(Float64, nsim);
mctest = BitArray(3, nsim);
@time runmc!(mcstat, mctest, nboot, P, R, α)
mean(mctest, 2)
