
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
                  "text": "What are the details of transaction TXN-9001?"
                }
              ]
            }
          ]
        }
        $$
    )
) AS AGENT_RESPONSE;