<?php

namespace App\Controller;

use App\TwitchConfig;
use App\TwitchHelper;
use App\TwitchVOD;
use Slim\Psr7\Request;
use Slim\Psr7\Response;
use Slim\Views\Twig;

class DashboardController
{
    /**
     * @var Twig
     */
    private $twig;

    public function __construct(Twig $twig)
    {
        $this->twig = $twig;
    }

    public function dashboard(Request $request, Response $response, array $args)
    {
        $total_size = 0;

        $streamerListStatic = TwitchConfig::getStreamers();
        $streamerList = [];

        $is_a_vod_deleted = false;

        $checkvod = isset($_GET['checkvod']);

        foreach ($streamerListStatic as $streamer) {

            $data = $streamer;

            $data['vods_raw'] = glob(TwitchHelper::vod_folder() . DIRECTORY_SEPARATOR . $streamer['username'] . "_*.json");

            $data['vods_list'] = [];

            $data['vods_size'] = 0;

            foreach ($data['vods_raw'] as $k => $v) {

                $vodclass = new TwitchVOD();
                $vodclass->load($v);

                if ($vodclass->is_recording){
                    $data['is_live'] = true;
                    $data['current_vod'] = $vodclass;
                }

                if ($checkvod && !$vodclass->is_recording) {
                    $isvalid = $vodclass->checkValidVod();
                    if (!$isvalid) {
                        $is_a_vod_deleted = true;
                        echo '<!-- deleted: ' . $vodclass->basename . ' -->';
                    }
                }

                if ($vodclass->segments) {
                    foreach ($vodclass->segments as $s) {
                        $data['vods_size'] += filesize(TwitchHelper::vod_folder() . DIRECTORY_SEPARATOR . $s['basename'] );
                    }
                }

                $data['vods_list'][] = $vodclass;

            }

            $total_size += $data['vods_size'];

            $streamerList[] = $data;

        }

        $log_lines = [];

        $logs = glob( __DIR__ . "/../../logs/*.log.json");
        
        if( $logs ){
        
            $last_log = $logs[ count($logs) - 1 ];

            if( $last_log ){
                
                $json = json_decode( file_get_contents( $last_log ), true );
                
                foreach( $json as $line ){

                    if( !TwitchConfig::cfg("debug") && $line["level"] == 'DEBUG' ) continue;

                    /*
                    $escaped_text = htmlentities($line["text"], ENT_QUOTES | ENT_HTML401 | ENT_SUBSTITUTE | ENT_DISALLOWED, 'UTF-8', true);

                    $text_line = "";
                    $date = \DateTime::createFromFormat("U.u", $line["date"]);
                    if($date) $text_line .= $date->format("Y-m-d H:i:s.v");
                    $text_line .= ' &lt;' . $line["level"] . '&gt; ';
                    $text_line .= $escaped_text;
                    echo '<div class="log_' . strtolower( $line["level"] ) . '">' . $text_line . '</div>';'
                    */

                    $line['date_string'] = \DateTime::createFromFormat("U.u", $line["date"])->format("Y-m-d H:i:s.v");

                    $log_lines[] = $line;

                }
            }

        }

        return $this->twig->render($response, 'dashboard.twig', [
            'streamerList' => $streamerList,
            'clips' => glob(TwitchHelper::vod_folder() . DIRECTORY_SEPARATOR . "clips" . DIRECTORY_SEPARATOR . "*.mp4"),
            'total_size' => $total_size,
            'is_a_vod_deleted' => $is_a_vod_deleted,
            'checkvod' => $checkvod,
            'log_lines' => $log_lines,
            'free_size' => disk_free_space( TwitchHelper::vod_folder() )
        ]);

    }

}