$token = Get-Content ".\token.txt"
$base_url = "https://api.telegram.org/bot$($token)/"
$tg_update_period = 3
$last_update_id = 0
$last_update_time = Get-Date

function GetUpdates() {
    $offset_string = ""
    if ($last_update_id -ne 0) {
        $offset_string = "&offset=$($last_update_id + 1)"
    }
    $response_json = Invoke-RestMethod -Uri "$($base_url)getUpdates?timeout=60$($offset_string)"
    $updates = $response_json.result
    return $updates
}

function SendMessage($chat_id, $text) {
    $payload_hashtable = @{
        text = $text
        parse_mode = "HTML"
        chat_id = $chat_id
    }
    $payload_json = $payload_hashtable | ConvertTo-Json
    Invoke-RestMethod "$($base_url)sendMessage" -Method Post -ContentType 'application/json; charset=utf-8' -Body $payload_json | Out-Null
}

while ($true) {
    if ((Get-Date) -ge $last_update_time.AddSeconds($tg_update_period)) {
        $last_update_time = Get-Date
        $updates = GetUpdates
        foreach ($update in $updates) {
            $last_update_id = $update.update_id
            Write-Host "$(Get-Date) #$($update.update_id) [$($update.message.from.id)] @$($update.message.from.username) ($($update.message.from.first_name)): $($update.message.text)"
            if ($update.message.text) {
                SendMessage $update.message.from.id $update.message.text
            }
        }
    }
}
