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

Swipe up to locator with expected position
    [Documentation]     This keyword performs a swipe up action until the specified locator reaches the expected Y-axis position on the screen.
    ...    \n Arguments: 
    ...    \n "locator" - target element to scroll to.
    ...    \n "expected_y_position" - Y-axis position (as a decimal between 0 and 1, where 1 is the bottom of the screen) the target locator should reach. (default is 0.89,to pass the tab bar position)
    ...    \n "boundary_y_threshold" - boundary element position to check on the Y-axis. e.g `BOUNDARY.BOTTOM`, `BOUNDARY.TOP`, `BOUNDARY.CENTER` (default is BOUNDARY.BOTTOM)
    ...    \n "swipe_attempts" - Maximum number of swipe attempts to locate the element at the expected position.
    ...    \n "swipe_duration" - Duration of each swipe action, in milliseconds, determining the speed of the swipe.
    ...    \n "swipe_range" - Swipe range value, calculates the start and end positions as percentages (e.g., 0.2 = 20% of screen height, swipe from center ±10%).
    ...    \n "swipe_base_position" - Swipe base position value, Center of swipe_range as percentages (e.g., 0.5 as center of screen).
    
    [Arguments]    ${locator}    ${expected_y_position}=${0.89}    ${boundary_y_threshold}=BOTTOM    ${swipe_attempts}=10    ${swipe_duration}=500    ${swipe_range}=0.4    ${swipe_base_position}=0.5

    ${window_height}          AppiumLibrary.Get window height
    ${window_width}           AppiumLibrary.Get window width
    ${expected_y}             BuiltIn.Evaluate    ${expected_y_position} * ${window_height}
    ${center_x}               BuiltIn.Evaluate    (${window_width} / 2)

    # Calculate swipe start and end from center Y-axis
    ${center_y}               BuiltIn.Evaluate    ${window_height} * ${swipe_base_position}
    ${swipe_offset}           BuiltIn.Evaluate    (${swipe_range} / 2) * ${window_height}
    ${finger_y_start_px}      BuiltIn.Evaluate    ${center_y} + ${swipe_offset}
    ${finger_y_end_px}        BuiltIn.Evaluate    ${center_y} - ${swipe_offset}

    ${is_expected}      BuiltIn.Set variable    ${FALSE}
    FOR  ${i}  IN RANGE   ${swipe_attempts}
        ${is_present}    BuiltIn.Run keyword and return status    AppiumLibrary.Element should be visible    ${locator}

        IF    ${is_present}
            ${element_position}      AppiumLibrary.Get element location    ${locator}
            ${element_size}          AppiumLibrary.Get element size    ${locator}
            ${element_y}             BuiltIn.Set variable    ${element_position["y"]}
            IF     '${boundary_y_threshold}' == 'BOTTOM'
                ${element_y}    BuiltIn.Evaluate    ${element_size["height"]} + ${element_y}
            ELSE IF    '${boundary_y_threshold}' == 'CENTER'
                ${element_y}    BuiltIn.Evaluate    (${element_size["height"]}/2) + ${element_y}
            END
            ${is_expected}    BuiltIn.Evaluate    ${element_y} < ${expected_y}
            Exit for loop if    ${is_expected}
        END
        Swipe custom   ${center_x}    ${finger_y_start_px}    ${center_x}    ${finger_y_end_px}    duration=${swipe_duration} 
    END
    BuiltIn.Should be true    ${is_expected}    msg=Not found expected element

*** Test Cases ***
Test swipe
    Open my app

    ${locator}    Set Variable    xpath=//android.widget.TextView[@content-desc="Product Title" and @text="Sauce Labs Backpack (violet)"]/parent::android.view.ViewGroup

    Swipe up to locator with expected position    ${locator}    

    [Teardown]    AppiumLibrary.Close Application