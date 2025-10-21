@{
    IncludeRules = @(
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSAvoidTrailingWhitespace',
        'PSUseCorrectCasing',
        'PSUseApprovedVerbs',
        'PSAvoidUsingAliases',
        'PSAvoidUsingWriteHost'
    )
    Rules = @{
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
        }
    }
}
