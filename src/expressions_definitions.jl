### Component Abstract Total Reserve Expressions ###
abstract type ComponentReserveExpressionType <: PSI.ExpressionType end
abstract type ComponentReserveUpExpressionType <: ComponentReserveExpressionType end
abstract type ComponentReserveDownExpressionType <: ComponentReserveExpressionType end

### Component Total Reserve Expressions ###
ThermalReserveUpExpression <: ComponentReserveUpExpressionType
ThermalReserveDownExpression <: ComponentReserveDownExpressionType
RenewableReserveUpExpression <: ComponentReserveUpExpressionType
RenewableReserveDownExpression <: ComponentReserveDownExpressionType
ChargeReserveUpExpression <: ComponentReserveUpExpressionType
ChargeReserveDownExpression <: ComponentReserveDownExpressionType
DischargeReserveUpExpression <: ComponentReserveUpExpressionType
DischargeReserveDownExpression <: ComponentReserveDownExpressionType

### Reserve Balance Expression ###
ComponentReserveBalanceExpression <: PSI.ExpressionType