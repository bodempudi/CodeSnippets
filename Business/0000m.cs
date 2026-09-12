int controlFlowIndent =
    GetControlFlowBooleanIndent(
        node,
        layoutContext);

if (controlFlowIndent >= 0)
{
    return controlFlowIndent;
}
