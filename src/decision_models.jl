abstract type HybridDecisionProblem <: PSI.DecisionProblem end
struct MerchantHybridEnergyOnly <: HybridDecisionProblem end
struct MerchantHybridCooptimized <: HybridDecisionProblem end
