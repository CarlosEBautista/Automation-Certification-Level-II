*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Desktop
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem


*** Variables ***
${WEB_URL}        https://robotsparebinindustries.com/#/robot-order
${CSV_URL}        https://robotsparebinindustries.com/orders.csv
${CSV_FILE}       orders.csv
${MAX_RETRIES}    5
${SHORT_INTERVAL}    1.5 sec
${MEDIUM_INTERVAL}    3 sec
${OUTPUT_DIR}           ${CURDIR}/output
${SCREENSHOT_DIR}       ${CURDIR}/screenshot
${RECEIPT_DIR}          ${CURDIR}/receipt

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download and Read CSV File as Table
    Process Each Order
    Create ZIP file of all receipts
    Close the browser
    Clear Directories

*** Keywords ***
Open the robot order website
    Open Available Browser    ${WEB_URL}
    Maximize Browser Window

Download and Read CSV File as Table
    ${orders}=    Get Orders
    Log    ${orders}

Get Orders
    Download    ${CSV_URL}    overwrite=True
    ${table}=    Read Table From Csv    ${CSV_FILE}    header=True
    [Return]    ${table}

Process Each Order
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Handle Single Order    ${order}
    END

Handle Single Order
    [Arguments]    ${order}
    Close the annoying modal
    Fill The Form    ${order}
    Wait Until Keyword Succeeds    ${MAX_RETRIES}    ${SHORT_INTERVAL}    Preview robot
    Take screenshot    ${order}
    Wait Until Keyword Succeeds    ${MAX_RETRIES}    ${SHORT_INTERVAL}    Submit order
    Store Order Receipt as PDF File    ${order}
    Wait Until Keyword Succeeds    ${MAX_RETRIES}    ${SHORT_INTERVAL}    Order new robot

Close the annoying modal
    Wait Until Element Is Visible    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Element When Clickable    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill The Form
    [Arguments]    ${row}
    Select From List By Value    id:head   ${row}[Head]
    Click Element    id:id-body-${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview robot
    Click Button    id:preview
    Wait Until Element Is Enabled    id:robot-preview-image

Take screenshot
    [Arguments]    ${row}
    ${name}=    Set Variable    ${row}[Order number]
    ${file_path}=    Catenate    SEPARATOR=    ${SCREENSHOT_DIR}/robot_image_    ${name}    .png
    Set Suite Variable    ${file_path}
    Sleep    ${SHORT_INTERVAL}
    Click Element When Clickable    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image    filename=${file_path}
    Sleep    ${SHORT_INTERVAL}

Submit order
    Execute Javascript    document.querySelector("#order").click()
    Element Should Be Visible    id:receipt
    Element Should Be Visible    id:order-another
    
Store Order Receipt as PDF File
    [Arguments]    ${row}
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    ${receipt_filename}    Catenate    SEPARATOR=    ${RECEIPT_DIR}/receipt_    ${row}[Order number]    .pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}
    Embed Robot Preview to PDF    ${receipt_filename}    ${row}

Embed Robot Preview to PDF
    [Arguments]    ${receipt_filename}    ${row}
    ${screenshot_file}=    Catenate    SEPARATOR=    ${SCREENSHOT_DIR}/robot_image_    ${row}[Order number]    .png
    Open Pdf    ${receipt_filename}
    ${image_files}=    Create List    ${screenshot_file}
    Add Files To PDF    ${image_files}    ${receipt_filename}    append=True

Order new robot
    Click Element When Clickable    id:order-another

Create ZIP file of all receipts
    ${ZIP_DIR} =    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Remove File    ${ZIP_DIR}    # This will delete the existing zip file if it exists
    Archive Folder With Zip    ${RECEIPT_DIR}    ${ZIP_DIR}

Close the browser
   Close All Browsers

Clear Directories
    Remove Directory    ${SCREENSHOT_DIR}    recursive=True
    Remove Directory    ${RECEIPT_DIR}       recursive=True
