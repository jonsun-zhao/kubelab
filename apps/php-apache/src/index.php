
<?php

$request = $_SERVER['REDIRECT_URL'];

switch ($request) {
    case '/' :
        require __DIR__ . '/views/index.php';
        break;
    case '' :
        require __DIR__ . '/views/index.php';
        break;
    case '/load' :
        require __DIR__ . '/views/load.php';
        break;
    case '/liveness' :
        echo "I am alive!";
        break;
    case '/readiness' :
        echo "I am ready!";
        break;
    default:
        echo "404";
        break;
}