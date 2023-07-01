### Component Abstract Total Reserve Expressions ###
abstract type ComponentReserveExpressionType <: PSI.ExpressionType end
abstract type ComponentReserveUpExpressionType <: ComponentReserveExpressionType end
abstract type ComponentReserveDownExpressionType <: ComponentReserveExpressionType end

### Component Total Reserve Expressions ###
struct ThermalReserveUpExpression <: ComponentReserveUpExpressionType end
struct ThermalReserveDownExpression <: ComponentReserveDownExpressionType end
struct RenewableReserveUpExpression <: ComponentReserveUpExpressionType end
struct RenewableReserveDownExpression <: ComponentReserveDownExpressionType end
struct ChargeReserveUpExpression <: ComponentReserveUpExpressionType end
struct ChargeReserveDownExpression <: ComponentReserveDownExpressionType end
struct DischargeReserveUpExpression <: ComponentReserveUpExpressionType end
struct DischargeReserveDownExpression <: ComponentReserveDownExpressionType end

### Reserve Balance Expression ###
struct ComponentReserveBalanceExpression <: PSI.ExpressionType end
struct TotalReserveUpExpression <: PSI.ExpressionType end
struct TotalReserveDownExpression <: PSI.ExpressionType end
