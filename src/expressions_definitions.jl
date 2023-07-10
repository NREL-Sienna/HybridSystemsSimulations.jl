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
abstract type TotalReserveUpExpression <: PSI.ExpressionType end
abstract type TotalReserveDownExpression <: PSI.ExpressionType end
struct TotalReserveOutUpExpression <: TotalReserveUpExpression end
struct TotalReserveOutDownExpression <: TotalReserveDownExpression end
struct TotalReserveInUpExpression <: TotalReserveUpExpression end
struct TotalReserveInDownExpression <: TotalReserveDownExpression end
