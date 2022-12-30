module hsodm_helper
using ProximalOperators
using DRSOM
using ProximalAlgorithms
using Plots
using Printf
using LazyStack
using HTTP
using LaTeXStrings
using LinearAlgebra
using Statistics
using Optim
using ForwardDiff
using ReverseDiff
using LineSearches

Base.@kwdef mutable struct Result{StateType,Int}
    name::String
    state::StateType
    k::Int
    traj::Vector{StateType}
end


basename = "HSODM"
naming(dirtype) = @sprintf("%s(%s)", basename, dirtype)
########################################################
# the DRSOM runner
########################################################
# provide 4 types of run:
# - run_drsomf: (forward), run DRSOM with forward automatic differentiation
# - run_drsomb: (backward), run DRSOM with backward automatic differentiation (recommended)
# - run_drsomd: (direct mode), run DRSOM with provided g(⋅) and H(⋅)
# - run_drsomd_traj: (direct mode) run add save trajactory



function run_drsomd(x0, f_composite,
    g, H; tol=1e-6, maxiter=100, maxtime=100, freq=1, record=true, direction=:cold
)
    ########################################################
    name = naming(direction)
    arr = Vector{DRSOM.HSODMState}()
    rb = nothing
    @printf("%s\n", '#'^60)
    @printf("running: %s with tol: %.3e\n", name, tol)
    iter = DRSOM.HSODMIteration(x0=x0, f=f_composite, g=g, H=H, mode=:direct, direction=direction)
    for (k, state::DRSOM.HSODMState) in enumerate(iter)
        (record) && push!(arr, copy(state))
        if k >= maxiter || state.t >= maxtime || DRSOM.drsom_stopping_criterion(tol, state)
            rb = (state, k)
            DRSOM.drsom_display(k, state)
            break
        end
        (k == 1 || mod(k, freq) == 0) && DRSOM.drsom_display(k, state)
    end
    @printf("finished with iter: %.3e, objval: %.3e\n", rb[2], rb[1].fx)
    return Result(name=name, state=rb[1], k=rb[2], traj=arr)
end


# general options for Optim
# GD and LBFGS, Trust Region Newton,
options = Optim.Options(
    g_tol=1e-6,
    iterations=10000,
    store_trace=true,
    show_trace=true,
    show_every=50,
)

end