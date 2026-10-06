SELECT TRY_PARSE_JSON(
    SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        'AGENT_SCOPE_LAB.AGENTS.BANKING_SECURE_AGENT!LIVE',
        $$
        {
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Perform the M12 controlled update test against SANDBOX."
                }
              ]
            }
          ]
        }
        $$
    )
) AS AGENT_RESPONSE;