
abstract type AbstractUncertaintyProblem end

struct ExpectationProblem{TS, TG, TH, TF, TP} <: AbstractUncertaintyProblem
    # defines ∫ g(S(h(x,u0,p)))*f(x)dx
    # 𝕏 = uncertainty space, 𝕌 = Initial condition space, ℙ = model parameter space,
    S::TS  # mapping,                 S: 𝕌 × ℙ → 𝕌
    g::TG  # observable(output_func), g: 𝕌 × ℙ → ℝⁿᵒᵘᵗ
    h::TH  # cov(input_func),         h: 𝕏 × 𝕌 × ℙ → 𝕌 × ℙ
    d::TF  # distribution,            pdf(d,x): 𝕏 → ℝ
    params::TP
    nout::Int
end 

# Constructor for general maps/functions
function ExpectationProblem(g, pdist, params; nout = 1)
    h(x,u,p) = x, p
    S(x,p) = x
    ExpectationProblem(S, g, h, pdist, params, nout)
end

# Constructor for DEProblems
function ExpectationProblem(sm::SystemMap, g, h, d; nout = 1)
    ExpectationProblem(sm, g, h, d, 
        ArrayPartition(deepcopy(sm.prob.u0),deepcopy(sm.prob.p)),
        nout)
end

distribution(prob::ExpectationProblem) = prob.d
mapping(prob::ExpectationProblem) = prob.S
observable(prob::ExpectationProblem) = prob.g
input_cov(prob::ExpectationProblem) = prob.h
parameters(prob::ExpectationProblem) = prob.params

# Builds integrand for DEProblems
function build_integrand(prob::ExpectationProblem{F}, ::Koopman) where F<:SystemMap
    @unpack S, g, h, d = prob
    function(x,p)
        ū, p̄ = h(x, p.x[1], p.x[2])
        g(S(ū,p̄), p̄)*pdf(d,x)   
    end
end

# Builds integrand for arbitrary functions
function build_integrand(prob::ExpectationProblem, ::Koopman)
    @unpack g, d = prob
    function(x,p)
        g(x,p)*pdf(d,x)
    end
end


## 
# struct CentralMomentProblem
#     ns::NTuple{Int,N}
#     altype::Union{NestedExpectation, BinomialExpansion} #Should rely be in solve
#     exp_prob::ExpectationProblem
# end

