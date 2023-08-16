package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
* State used to give full explanations of updates.
*/
class PatchState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	var lerpList:Array<Bool> = [];
	private var iconArray:Array<AttachedSprite> = [];
	private var patchStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;
	var nameText:FlxText;
	var roleText:FlxText;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;
	var descBox:FlxSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("In the Patch Notes", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite().loadGraphic(Paths.image('gradient'));
		add(gradient);
		gradient.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if(leMods.length > 1 && leMods[0].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if(modSplit[1] == '1')
							pushModPatchToList(modSplit[0]);
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}

		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			pushModPatchToList(folder);
		}
		#end

		var pisspoop:Array<Array<String>> = [ //Ver - Icon name - Update Ver - Update Name - Description - Link - BG Color
			['The Mod'],
                        ['1.0.0'.               'widol',                "1.0.0", "", "The release of the mod!', '', 	'4DB33C']
		];
		
		for(i in pisspoop){
			patchStuff.push(i);
		}
	
		for (i in 0...patchStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, patchStuff[i][0], !isSelectable, false);
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			optionText.targetY = i;
			lerpList.push(true);
			grpOptions.add(optionText);

			if(isSelectable) {
				if(patchStuff[i][7] != null)
				{
					Paths.currentModDirectory = patchStuff[i][7];
				}

				var icon:AttachedSprite = new AttachedSprite('patch/' + patchStuff[i][1]);
				icon.xAdd = -icon.width - 10;
				icon.sprTracker = optionText;
	
				iconArray.push(icon);
				add(icon);
				icon.copyState = true;
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}
		
		descBox = new FlxSprite(-300, 0);
		descBox.makeGraphic(Std.int(FlxG.width/2 - 70), FlxG.height, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		nameText = new FlxText(-300, 25, 570, "", 32);
		nameText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameText.scrollFactor.set();
		add(nameText);

		roleText = new FlxText(-300, 100, 570, "", 24);
		roleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		roleText.scrollFactor.set();
		add(roleText);

		descText = new FlxText(-300, 200, 570, "", 16);
		descText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		add(descText);

		bg.color = getCurrentBGColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = getCurrentBGColor();
			bgScroll2.color = getCurrentBGColor();
		}
		gradient.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		if(!quitting)
		{
			if(patchStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(FlxG.mouse.wheel != 0)
					{
						changeSelection(-shiftMult * FlxG.mouse.wheel);
					}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT) {
				if (patchStuff[curSelected][5] != null && patchStuff[curSelected][5].length > 0) {
					CoolUtil.browserLoad(patchStuff[curSelected][5]);
				}
			}
			if (controls.BACK)
			{
				if(colorTween != null) {
					colorTween.cancel();
				}
				if(bgScrollColorTween != null) {
					bgScrollColorTween.cancel();
				}
				if(bgScroll2ColorTween != null) {
					bgScroll2ColorTween.cancel();
				}
				if(gradientColorTween != null) {
					gradientColorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		final lerpVal:Float = CoolUtil.clamp(elapsed * 12, 0, 1);
		for (i=>item in grpOptions.members)
		{
			item.visible = item.active = lerpList[i] = true;
			if (Math.abs(item.targetY) > 7 && !(curSelected == 1 || curSelected == grpOptions.length - 1))
				item.visible = item.active = lerpList[i] = false;

			if(!item.isBold)
			{
				@:privateAccess {
					if (lerpList[i]) {
						item.y = FlxMath.lerp(item.y, (item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd, lerpVal);
						if(item.targetY == 0)
							item.x = FlxMath.lerp(item.x, (FlxG.width - item.width) - 115, lerpVal);
						else
							item.x = FlxMath.lerp(item.x, (FlxG.width - item.width) - 15, lerpVal);
					} else {
						item.y = ((item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd);
						if(item.targetY == 0)
							item.x = ((FlxG.width - item.width) - 115);
						else
							item.x = ((FlxG.width - item.width) - 15);
					}
				}
			} else {
				@:privateAccess {
					if (lerpList[i])
						item.y = FlxMath.lerp(item.y, (item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd, lerpVal);
					else
						item.y = ((item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd);
				}
				item.x = (FlxG.width - item.width - 25);
			}
		}

		super.update(elapsed);
	}

	var nameTextTwn:FlxTween = null;
	var roleTextTwn:FlxTween = null;
	var descTextTwn:FlxTween = null;
	var boxTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = patchStuff.length - 1;
			if (curSelected >= patchStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			if(bgScrollColorTween != null) {
				bgScrollColorTween.cancel();
			}
			if(bgScroll2ColorTween != null) {
				bgScroll2ColorTween.cancel();
			}
			if(gradientColorTween != null) {
				gradientColorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			if (!ClientPrefs.settings.get("lowQuality")) {
				bgScrollColorTween = FlxTween.color(bgScroll, 1, bgScroll.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						bgScrollColorTween = null;
					}
				});
				bgScrollColorTween = FlxTween.color(bgScroll2, 1, bgScroll2.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						bgScrollColorTween = null;
					}
				});
			}
			gradientColorTween = FlxTween.color(gradient, 1, gradient.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		for (icon in iconArray) {
			icon.active = true;
			icon.visible = true;
		}

		if(nameTextTwn != null) nameTextTwn.cancel();
		nameText.text = patchStuff[curSelected][2];
		nameText.x = -200;
		nameTextTwn = FlxTween.tween(nameText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(roleTextTwn != null) roleTextTwn.cancel();
		roleText.text = patchStuff[curSelected][3];
		roleText.x = -200;
		roleTextTwn = FlxTween.tween(roleText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(descTextTwn != null) descTextTwn.cancel();
		descText.text = patchStuff[curSelected][4];
		descText.x = -200;
		descTextTwn = FlxTween.tween(descText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(boxTween != null) boxTween.cancel();
		descBox.x = -200;
		boxTween = FlxTween.tween(descBox, {x: 0}, 0.7, {ease: FlxEase.expoOut});
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModPatchToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var patchFile:String = null;
		if(folder != null && folder.trim().length > 0) patchFile = Paths.mods(folder + '/data/patch.txt');
		else patchFile = Paths.mods('data/patch.txt');

		if (FileSystem.exists(patchFile))
		{
			var firstarray:Array<String> = File.getContent(patchFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 7) arr.push(folder);
				patchStuff.push(arr);
			}
			patchStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor() {
		var bgColor:String = patchStuff[curSelected][6];
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return patchStuff[num].length <= 1;
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		bg.offset.set();
	}
}
