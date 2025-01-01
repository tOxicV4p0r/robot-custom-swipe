*** Settings ***
Library    AppiumLibrary
Library    RequestsLibrary

Variables    ./action_commands.yaml

*** Variables ***
${REMOTE_URL}    http://localhost:4723

*** Keywords ***
Open my app
    [Arguments]    ${no_reset}=${True}

    &{CAPABILITIES} =    BuiltIn.Create Dictionary    
    ...    platformName=Android
    ...    appium:automationName=UiAutomator2
    ...    appium:noReset=${no_reset}
    ...    appium:newCommandTimeout=0

    Open Application    remote_url=${REMOTE_URL}    &{CAPABILITIES}

Get session url
    ${session_id}    AppiumLibrary.Get appium sessionId
    ${url}       BuiltIn.Set variable     ${REMOTE_URL}/session/${session_id}
    RETURN    ${url}

Send command via http
    [Arguments]    ${command}
    ${url}       Get session url
    ${response}    POST    url=${url}/actions    json=${command}    expected_status=anything

Swipe custom
    [Documentation]    Customized swipe: swipe, hold at the end position for 100 ms, then release.
    [Arguments]    ${start_x}    ${start_y}    ${end_x}    ${end_y}    ${duration}=${500}
    ${custom_command.swipe.actions[0].actions[0].x}    BuiltIn.Set variable    ${start_x}
    ${custom_command.swipe.actions[0].actions[0].y}    BuiltIn.Set variable    ${start_y}
    ${custom_command.swipe.actions[0].actions[2].x}    BuiltIn.Set variable    ${end_x}
    ${custom_command.swipe.actions[0].actions[2].y}    BuiltIn.Set variable    ${end_y}
    ${custom_command.swipe.actions[0].actions[2].duration}    BuiltIn.Set variable    ${duration}
    ${custom_command.swipe.actions[0].actions[3].x}    BuiltIn.Set variable    ${end_x}
    ${custom_command.swipe.actions[0].actions[3].y}    BuiltIn.Set variable    ${end_y}
    Send command via http    ${custom_command.swipe}

*** Test Cases ***
Test swipe
    Open my app

    ${height}      Get Window Height
    ${width}       Get Window Width

    ${center_x}    Evaluate    int(${width}*0.5)
    ${start_y}     Evaluate    int(${height}*0.6)
    ${end_y}       Evaluate    int(${height}*0.5)

    Log To Console    \n

    FOR    ${counter}    IN RANGE   3
        Swipe custom    ${center_x}    ${start_y}    ${center_x}    ${end_y}    100
        # AppiumLibrary.Swipe    ${center_x}    ${start_y}    ${center_x}    ${end_y}    1000
        Sleep    1s
    END

    [Teardown]    AppiumLibrary.Close Application