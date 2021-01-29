lock();
player.moveHere();
player.jump(2);
player.say("hello world");
mob = getClosestMob();
mob.emote("wave");
player.say("that's nice!");
player.jump();
exit();