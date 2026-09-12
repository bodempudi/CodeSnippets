bool compoundComparisonOperator =
    (previousText == "<" &&
        (currentText == "=" ||
         currentText == ">")) ||
    (previousText == ">" &&
        currentText == "=") ||
    (previousText == "!" &&
        (currentText == "=" ||
         currentText == "<" ||
         currentText == ">"));

bool tight =
    currentText == "." ||
    currentText == "," ||
    currentText == ")" ||
    currentText == ";" ||
    previousText == "." ||
    previousText == "(" ||
    compoundComparisonOperator;
