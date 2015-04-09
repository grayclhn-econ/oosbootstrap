## Taken from version 0.4
cld{T<:Integer }(x::T, y::T) = div(x,y)+(!signbit(x$y)&(rem(x,y)!=0))

function makedata!(y::Vector{Float64}, x::Matrix{Float64})
    n = length(y)
    size(x)[1] == n || error("x and y have incompatible dimensions")
    randn!(y)
    for i in 1:n
        x[i] = 1
    end
    if length(x) > n
        for i in (n+1):length(x)
            x[i] = randn()
        end
    end
end

## Let's just do one for forecast unbiasedness first.
function oosstat!(f::Vector{Float64}, coef::Vector{Float64},
                  y::Vector{Float64}, x::Matrix{Float64})
    R = length(y) - length(f)
    for t = R:(length(y) - 1)
        coef[:] = x[1:t,:] \ y[1:t]
        f[t-R+1] = y[t+1] - (x[t+1,:] * coef)[1]
    end
    mean(f)
end
    
function bootmean!(ffull::Vector{Float64}, coef::Vector{Float64},
                   y::Vector{Float64}, x::Matrix{Float64})
    coef[:] = x \ y
    ffull[:] = y - x * coef
    mean(ffull)
end

## Let's just do one for absolute forecast error.
function oosstat2!(f::Vector{Float64}, coef::Vector{Float64},
                  y::Vector{Float64}, x::Matrix{Float64})
    R = length(y) - length(f)
    for t = R:(length(y) - 1)
        coef[:] = x[1:t,:] \ y[1:t]
        f[t-R+1] = abs(y[t+1] - (x[t+1,:] * coef)[1])
    end
    mean(f)
end
    
function bootmean2!(ffull::Vector{Float64}, coef::Vector{Float64},
                   y::Vector{Float64}, x::Matrix{Float64})
    coef[:] = x \ y
    ffull[:] = abs(y - x * coef)
    mean(ffull)
end

function runmc!(mcresults, nboot, P, R, k, α,
                oosstat!, bootmean!, truemean)
    y = Array(Float64, P+R)
    x = Array(Float64, P+R, k)
    yboot = similar(y)
    xboot = similar(x)
    f = Array(Float64,  P)
    ffull = Array(Float64, P+R)
    coef = Array(Float64, k)
    bootvalue = Array(Float64, nboot)
    
    for i in 1:length(mcresults)
        makedata!(y, x)
        oosvalue = oosstat!(f, coef, y, x) - truemean
        bootnull = bootmean!(ffull, coef, y, x)

        for j in 1:nboot
            blockboot!(yboot, xboot, y, x, 8)
            @inbounds bootvalue[j] = oosstat!(f, coef, yboot, xboot) - bootnull
        end
        crit = quantile(bootvalue, [α/2, 1 - α/2])
        @inbounds mcresults[i] = oosvalue < crit[1] || oosvalue > crit[2]
    end
end

mcresults1 = Array(Bool, 600)
@time runmc!(mcresults1, 499, 120, 240, 5, 0.05, oosstat!, bootmean!, 0)
mcresults2 = Array(Bool, 1500)
@time runmc!(mcresults2, 499, 120, 240, 5, 0.05, oosstat2!, bootmean2!, sqrt(2/π))
