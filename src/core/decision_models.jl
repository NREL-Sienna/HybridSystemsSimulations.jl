abstract type HybridDecisionProblem <: PSI.DecisionProblem end

struct MerchantHybridEnergyCase <: HybridDecisionProblem end
struct MerchantHybridEnergyFixedDA <: HybridDecisionProblem end
struct MerchantHybridCooptimizerCase <: HybridDecisionProblem end
