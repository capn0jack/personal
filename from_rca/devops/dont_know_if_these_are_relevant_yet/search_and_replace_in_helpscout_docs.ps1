$replacementArray = @(
    ('“','"'),
    ('”','"'),
    ('/','\/'),
    (':','\:'),
    ('caredfor.com','shoutout.com'),
    ('caredfor','shoutout'),
    ('CaredFor','Shoutout'),
    ('Cared For','Shoutout'),
    ('Caredfor','Shoutout')
)

$user = '9d4a936ecff536bbb72819810445fce8c289b5a6'
$pass = 'X'
$pair = "$($user):$($pass)"
$id = '60a6cc4cdca0fd46b9357837'
$uriHelpScoutDocsApi = 'https://docsapi.helpscout.net/v1'
$uriListArticlesByCollection = "$uriHelpScoutDocsApi/collections/$id/articles"
$uriBaseArticle = "$uriHelpScoutDocsApi/articles"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

$content = Invoke-RestMethod -Headers $Headers -Uri "$uriListArticlesByCollection"
$numPages = $content.articles.pages
foreach ($pageNum in 1..$numPages) {
    Write-Host "$uriListArticlesByCollection`?page=$pageNum"
    $content = Invoke-RestMethod -Headers $Headers -Uri "$uriListArticlesByCollection`?page=$pageNum"
    $articles = $content.articles.items
    foreach ($article in $articles) {
        $articleId = $article.id
        $articleContent = Invoke-RestMethod -Headers $Headers -Uri "$uriBaseArticle/$articleId"
        $articleText = $articleContent.article.text
        $articleName = $articleContent.article.name
        # If ($articleName -like "TEMP_DELETEME*") {
            $articleName
            Write-Host "$uriBaseArticle/$articleId"
            $uri = "$uriBaseArticle/$articleId"
            If ($articleText -like "*help.caredfor.com*") {
                Write-Warning "Link needs to be updated."
            }
            foreach ($replacement in $replacementArray) {
                $articleText = $articleText -creplace $replacement[0],$replacement[1]
                $articleName = $articleName -creplace $replacement[0],$replacement[1]
            }
            $body = @{
                'status'='published';
                'name'="$articleName";
                'text'="$articleText"
            }
            $body = $body | ConvertTo-Json
            # $body = "{
            #     `n  `"text`": `"<p>`\n`\tNavigate to&nbsp;Menu&nbsp;&gt;&nbsp;Dashboard&nbsp;&gt;&nbsp;Toggle Admin Menu (mobile only)&nbsp;&gt;&nbsp;Surveys &amp; Assessments:</p><ul>`\n`\t`\n<li>Tap the green&nbsp;+ New Survey&nbsp;button in the top right corner, then select&nbsp;Create Survey.</li>`\t`\n<li>Enter a survey Title.</li>`\t`\n<li>Enter a short call-to-action message.&nbsp;This message will be included in the stream and notification sent to the member.`\n`\t`\n<ul>`\n`\t`\t`\n<li>Tap&nbsp;Insert First Name&nbsp;to personalize the message by including the name of the member taking the survey. Anywhere you see `"%first_name%`" will be replaced with the member's first name in the final message.</li>`\t</ul></li>`\t`\n<li>Add&nbsp;optional admin facing information to provide additional context, like scoring information. These details will be visible to all admins on the survey management page.</li>`\t`\n<li>Mark the&nbsp;checkbox&nbsp;if you would like to send reminder notifications to members who have not completed the survey. These reminders are sent via SMS 2 days before the survey is set to expire.&nbsp;`\n`\t`\n<ul>`\n`\t`\t`\n<li>You can customize this reminder message by going to&nbsp;Menu&nbsp;&gt;&nbsp;Dashboard&nbsp;&gt;&nbsp;Toggle Admin Menu (mobile only)&nbsp;&gt;&nbsp;Notification Messages, then scroll down to the Surveys heading.</li>`\t</ul></li>`\t`\n<li>Tap the&nbsp;+ Add Question&nbsp;button to begin building your survey. For each question:`\n`\t`\n<ul>`\n`\t`\t`\n<li>Enter the question text.</li>`\t`\t`\n<li>Select a question type and enter the corresponding answer choices.&nbsp;<em>(Descriptions of all supported question types are listed below)</em></li>`\t`\t`\n<li>Mark the checkbox if you want to make the question required.</li>`\t`\t`\n<li>To allow members to add their own supplemental comments, turn the toggle switch on.</li>`\t</ul></li>`\t`\n<li>Once you've finished adding all your questions, tap&nbsp;Save&nbsp;in the top right corner.</li></ul><p>`\n`\tNote - You can `\n`\t<a href=`\`"https://help.shoutout.com/article/157-edit-or-stop-a-survey`\`">edit survey questions</a> up until the first time it is sent.</p><h3>Question Types</h3><ul>`\n`\t`\n<li>Multiple choice&nbsp;- Provide members with up to 5 answer choices, displayed in a list. Members can only select one answer.&nbsp; `"Yes`" or `"No`" questions are a typical use case for this question type.`\n`\t`\n<ul>`\n`\t`\t`\n<li>Multiple choice questions can be used for conditional survey logic. Follow <a href=`\`"https://help.shoutout.com/article/154-conditional-survey-questions`\`">these instructions for setting up conditional questions</a>.</li>`\t</ul></li>`\t`\n<li>Picklist&nbsp;- If you have more than 5 answer choices, use the picklist question type. Answer options will display in a drop down box for members to scroll through. Members can only select one answer.</li>`\t`\n<li>Scale&nbsp;- The scale question type allows you to set a max and min value along with an icon (happy/sad, thumbs up/down, or arrow up/down) to a given question. Typical questions include `"Rate your mood`" or `"How likely are you to recommend our facility to someone seeking treatment?`"</li>`\t`\n<li>Open Ended&nbsp;- This provides members with a blank space to type in their own response. The open ended question type allows you to ask your audience to provide more detailed responses for a given question.</li></ul><p>`\n`\tShoutout has a `\n`\t<a href=`\`"https://help.shoutout.com/article/178-template-library`\`">library of template surveys</a> available to use. Email us at <a href=`\`"mailto:mailto:support@shoutout.com`\`">support@shoutout.com</a> to have a template added to your app.&nbsp;</p>`",
            #     `n  `"status`": `"published`",
            #     `n  `"name`": `"TEMP_DELETEME_Create a Survey`"
            #     `n}"
            $params = @{
                Uri         = $uri
                Headers     = $Headers
                Method      = 'PUT'
                Body        = $body
                ContentType = 'application/json'
            }

            # $body | Out-File c:\temp\bad_char.txt
            #Invoke-RestMethod -Method PUT -Headers $Headers -Uri "$uriBaseArticle/$articleId" -Body "$body" -ContentType 'application/json' -Verbose
            Invoke-RestMethod @params
            # Invoke-WebRequest -Method PUT -Headers $Headers -Uri $uri -Body $body -ContentType 'application/json' -Verbose
        # }
    }
}