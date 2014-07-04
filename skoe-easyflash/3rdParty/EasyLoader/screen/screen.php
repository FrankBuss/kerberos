<?php

// ←↑→↓↵◉‥
// ┌┐└┘─│╵╶
// ╭╮
// ■

#---------┃---------┃---------┃---------
$t = <<<HERE
┌■ ■E■a■s■y■F■l■a■s■h■ ╶╶╶╶╶╶╶╶╶╶╶╶╶┐■ ■I■n■f■o■ ╶╶╶╶╶╶╶┐
╵                        │             │
╵                        │ xxxxxxxxxxx │
╵                        │ xxxxxxxxxxx │
╵                        │             │
╵                        │ xxxxxxxxxxx │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │             │
╵                        │ xxxxxxxxxx  │
╵                        │ xxxxxxxx    │
└────────────────────────┘─────────────┘
HERE;
#---------┃---------┃---------┃---------
$help = <<<HERE
 To navigate
 use key/joy
 up or down 
 or<■F■5=■F■7>

 Scroll page
 left/right
 or<■F■6=■F■8>

 Start Prog:
<■F■1=■R■E■T=■F■I■R■E>

 Quit:<■F■2>
HERE;
#---------┃---------┃---------┃---------
$msg = <<<HERE
┌╶╶╶╶╶╶╶╶╶╶╶╶╶┐
╵             │
╵ Please Wait │
╵             │
└─────────────┘
HERE;
#---------┃---------┃---------┃---------




/*
** COLORS!
*/


$col_main_border = 5; //GREEN
$col_main_inner = 13; //LIGHT_GREEN
$col_main_wait = 3; //CYAN
$col_info_border = 6; //BLUE
$col_info_inner = 14; //LIGHT_BLUE
$col_slider = 3;

$LINE['col_line_top'] =
	str_repeat(chr($col_main_border), 26).
	str_repeat(chr($col_info_border), 14);
$LINE['col_line_head'] =
	str_repeat(chr($col_main_border), 1).
	str_repeat(chr($col_main_inner), 24).
	str_repeat(chr($col_main_border), 1).
	str_repeat(chr(1), 13).
	str_repeat(chr($col_info_border), 1);
$LINE['col_line_help'] =
	str_repeat(chr($col_main_border), 1).
	str_repeat(chr($col_main_inner), 24).
	str_repeat(chr($col_main_border), 1).
	str_repeat(chr($col_info_inner), 13).
	str_repeat(chr($col_info_border), 1);
$LINE['col_line_box_a'] =
	str_repeat(chr($col_main_border), 26).
	str_repeat(chr($col_info_inner), 13).
	str_repeat(chr($col_info_border), 1);
$LINE['col_line_box_b'] =
	str_repeat(chr($col_main_border), 6).
	str_repeat(chr($col_main_wait), 13).
	str_repeat(chr($col_main_border), 7).
	str_repeat(chr($col_info_inner), 13).
	str_repeat(chr($col_info_border), 1);

$col_pattern = array(
	'col_line_top',
	'col_line_help',
	'col_line_head',
	'col_line_head',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_box_a',
	'col_line_box_a',
	'col_line_box_b',
	'col_line_box_a',
	'col_line_box_a',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_help',
	'col_line_head',
	'col_line_help',
	'col_line_top',
);

$end = 0x400;
// lines
foreach($LINE AS $na => $dummy){
	$end -= 40;
	$ofs[$na] = $end;
}
// pattern
$end -= 25;
$ofs['col_pattern'] = $end;
$ofs['start_screen_decode'] = $end;
// output offsets
$f = fopen('build/screen.asm', 'w');
foreach($ofs AS $na => $pos){
	fwrite($f, '.const '.$na.' = '.sprintf('$%x', $pos)."\n");
}
fwrite($f, '.const color_slider_off = '.$col_main_border."\n");
fwrite($f, '.const color_slider_on = '.$col_slider."\n");

/*
** ENCODE SCREEN
*/


$chars = array(
  '┌' => 0,
  '╶' => 1,
  '┐' => 2,

  '‥' => 8,

  '╵' => 128,
  '└' => 129,
  '─' => 130,
  '┘' => 131,
  '│' => 132,

  '╭' => 159,
  '╮' => 137,
  
  '<' => 158,
  '>' => 30,
  '=' => 0xe0,
);

foreach($chars AS $k => $v){
	$chars[$k] = chr($v);
}

$t = strtr($t, $chars);
$t = preg_replace('!■(.)!e', 'chr(0x80 + ord("\1"))', $t);
$t = explode("\n", $t);

$help = strtr($help, $chars);
$help = preg_replace('!■(.)!e', 'chr(0x80 + ord("\1"))', $help);
$help = explode("\n", $help);

$msg = strtr($msg, $chars);
$msg = preg_replace('!■(.)!e', 'chr(0x80 + ord("\1"))', $msg);
$msg = explode("\n", $msg);

foreach($help AS $k=>$v){
	$kk = $k + 7;
	$t[$kk] = substr($t[$kk], 0, 26).str_pad($v, 13, ' ').substr($t[$kk], -1);
}

foreach($msg AS $k=>$v){
	$kk = $k + 10;
	$t[$kk] = substr($t[$kk], 0, 5).str_pad($v, 15, ' ').substr($t[$kk], 5+15);
}

foreach(array(
	 2*40+27 => array_merge(range(0x14, 0x18),array(0x20),range(0x19,0x1d)),
	 3*40+27 => array_merge(range(0x94, 0x98),array(0x20),range(0x99,0x9d)),
	 5*40+27 => range(0x85, 0x8f),
	22*40+27 => array_merge(range(0x90, 0x93),range(0x06,0x0b)),
	23*40+27 => range(0x0c, 0x13),
) AS $o1 => $data){
	foreach($data AS $o2 => $val){
		$t[$o1/40][$o1 % 40 + $o2] = chr($val);
	}
}

$screen = repair_case(implode('', $t));

// $screen = the screen ($400-$7e7)

/*
** ENCODE COLORS
*/

$cols = '';
foreach($col_pattern AS $ln){
	$cols .= chr($ofs[$ln] & 0xff); // just lower byte
}
asort($ofs);
foreach($ofs AS $na => $dummy){
	if(isset($LINE[$na])){
		$cols .= $LINE[$na];
	}
}

// $cols = the colors (before $400)


/*
** SPRITES!!!
*/

// setup sprites (in screen area)
$screen .= str_repeat(chr(0), 16).chr(0x20).chr(0x21).chr(0x22).chr(0x23).chr(0x24).chr(0x25).chr(0x26).chr(0x27);

$sprite_image = imagecreatefrompng('graphics/sprites.png');

$sprites = '';
foreach(array(
	array(0*24, 0, 0x949494),
	array(1*24, 0, 0x949494),
	array(2*24, 0, 0x949494),
	array(3*24, 0, 0x949494),

	array(5*8, 0, 0xd08727),
	array(5*8, 0, 0x853921),

	array(4*24, 0, 0xd08727),
	array(4*24, 0, 0x853921),
) AS $a_sprite){
	list($x, $y, $col) = $a_sprite;
	for($y2=0; $y2<21; $y2++){
		for($x2=0; $x2<3; $x2++){
			$byte = 0;
			for($x3=0; $x3<8; $x3++){
//var_dump(sprintf('%08x', imagecolorat($sprite_image, $x+$x2*8+$x3, $y+$y2)));
				if((imagecolorat($sprite_image, $x+$x2*8+$x3, $y+$y2) & 0xffffff) == $col){
					$byte |= 1 << (7 - $x3);
				}
			}
			$sprites .= chr($byte);
		}
	}
	$sprites .= chr(0);
}

//echo ff($sprites);

/*
** TOGETHER
*/

$all = $cols.$screen.$sprites.chr(0);


//echo $all;

$p1 = pack1($all);

echo $p1;

$s = array();
for($i=0; $i<strlen($screen); $i++)
	$s[] = ord($screen[$i]);
fwrite($f, '.const the_complete_start_screen = List().add('.implode(', ', $s).')'."\n");

fclose($f);


/*
var_dump(strlen($all),strlen($p1));

echo ff($p1);
echo "***\n";
unpack1($p1);

echo "***\n";
echo ff($all);
*/


function repair_case($t){
	for($i=0; $i<strlen($t); $i++){
		$o = ord($t[$i]);
		if($o >= 0x41 && $o <= 0x5a){
			$t[$i] = chr($o + 0x20);
		}else if($o >= 0x61 && $o <= 0x7a){
			$t[$i] = chr($o - 0x20);
		}
		if($o >= 0xc1 && $o <= 0xda){
			$t[$i] = chr($o + 0x20);
		}else if($o >= 0xe1 && $o <= 0xfa){
			$t[$i] = chr($o - 0x20);
		}
	}
	return $t;
}

function pack1($t){
	$o = '';
	for($i=0; $i<strlen($t);){
		for($j=0; $j<128; $j++){
			if(($i+$j+2 < strlen($t)) && ($t[$i+$j] === $t[$i+$j+1]) && ($t[$i+$j+2] === $t[$i+$j]))
				break;
		}
		if($j > 0){
//			echo 'pass '.$j.' "'.ff(substr($t, $i, $j)).'"'."\n";
			$o .= chr($j).substr($t, $i, $j);
			$i+=$j;
		}else{
			for($j=0; $i+$j < strlen($t) && $j<128; $j++){
				if($t[$i] != $t[$i+$j])
					break;
			}
//			echo 'copy '.$j.' "'.ff($t[$i]).'"'."\n";
			$o .= chr(256 - $j).$t[$i];
			$i+=$j;
		}
	}
	return $o;
}

function unpack1($t){
	for($i=0; $i<strlen($t); ){
		if(ord($t[$i]) < 128){
			echo 'pass '.ord($t[$i]).' "'.ff(substr($t, $i+1, ord($t[$i]))).'"'."\n";
			$i += 1+ord($t[$i]);
		}else{
			echo 'copy '.(256 - ord($t[$i])).' "'.ff($t[$i+1]).'"'."\n";
			$i += 2;
		}
	}
}

function ff($t){
	$O = '';
	for($i=0; $i<strlen($t); $i++){
		$o = ord($t[$i]);
		if($o >= 0x20 && $o <= 0x7a){
			$O .= $t[$i];
		}else{
			$O .= sprintf('[$%02x]', $o);
		}
	}
	return $O;
}


?>