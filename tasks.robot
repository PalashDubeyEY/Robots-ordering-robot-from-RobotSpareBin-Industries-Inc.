*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             Collections
# Library    html_tables.py
Library             RPA.Tables
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.RobotLogListener
Library             RPA.Dialogs
Library             OperatingSystem
Library             DateTime


*** Tasks ***
Process all the orders from csv file and save all the details
    # Mute Run On Failure
    Get csv url
    Open the order site
    Fill in the order form using the data from the csv file
    Name and make the ZIP
    [Teardown]    Log out and close the browser


*** Keywords ***
Get csv url
    Download    https://robotsparebinindustries.com/orders.csv    verify=${False}    overwrite=True

Open the order site
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Click OK
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK

Make order
    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Fill out 1 order
    [Arguments]    ${orders}
    Click OK
    Wait Until Page Contains Element    class:form-group
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    2min    500ms    Make order

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    # Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${OUTPUT_DIR}${/}robot-output${/}receipt_${order_id}.pdf

    Wait Until Element Is Visible    id:robot-preview-image
    # Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot-output${/}robot_${order_id}.png
    Combine receipt with robot image to a PDF
    ...    ${OUTPUT_DIR}${/}robot-output${/}receipt_${order_id}.pdf
    ...    ${OUTPUT_DIR}${/}robot-output${/}robot_${order_id}.png

Fill in the order form using the data from the csv file
    ${orders}=    Read table from CSV    path=orders.csv
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Fill out 1 order    ${order}
        Save order details
        Return to order form
    END

Combine receipt with robot image to a PDF
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_filename}    ${False}
    Close Pdf    ${receipt_filename}

Log out and close the browser
    Close Browser

Name and make the ZIP
    Archive Folder With Zip    ${OUTPUT_DIR}${/}robot-output    orders_archive.zip
