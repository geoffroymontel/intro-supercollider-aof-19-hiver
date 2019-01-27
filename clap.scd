// 1 : regardez la vidéo d'une interprétation de Clapping Music de Steve Reich
// https://www.youtube.com/watch?v=QNZQzpWCTlA

// 2 : pour évaluer une ligne ou un bloc (délimité par des parenthèses sur des lignes)
// mettez-vous sur la ligne ou la parenthèse et appuyez sur cmd+entrée ou ctrl+entrée

// à tout moment, vous pouvez vous mettre sur un mot clé du langage et taper sur cmd+d ou ctrl+d pour avoir la documentation associée

// 3 : évaluez ce bloc, vous devriez entendre un clap
(
~clap = Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+ "clap.wav", action: { |buf| buf.play; });
)

// 4 : évaluez ce bloc pour chargez les différents claps de chacun des interprêtes
(
~clap1SampleNames = ["clap1-1.wav", "clap1-2.wav", "clap1-3.wav", "clap1-4.wav"];
~clap2SampleNames = ["clap2-1.wav", "clap2-2.wav", "clap2-3.wav", "clap2-4.wav"];
~clap1Samples = ~clap1SampleNames.collect({ |fileName|
	Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+ fileName);
});
~clap2Samples = ~clap2SampleNames.collect({ |fileName|
	Buffer.read(server: s, path: Document.current.dir +/+ "samples" +/+  fileName);
});
)

// 5 : on crée un synthé basique pour jouer un sample
// et un autre qui imite très pauvrement un clap
(
SynthDef(\samplePlayer, { |out = 0, bufnum|
	Out.ar(out, PlayBuf.ar(numChannels: 2, bufnum: bufnum, doneAction: Done.freeSelf));
}).add;

SynthDef(\fakeClap, { |out = 0|
	var sig;
	sig = WhiteNoise.ar;
	sig = sig * EnvGen.ar(envelope: Env.perc(attackTime: 0.001, releaseTime: 0.1), doneAction: Done.freeSelf) * -6.dbamp;
	Out.ar(out, sig);
}).add;
)

// évaluez chacune de ces deux lignes
Synth(\fakeClap); // ça sonne plus comme une charley fermée :)
Synth(\samplePlayer, [out: 0, bufnum: ~clap]); // notre synthé qui joue un clap

// les routines permettent de séquencer à la main deux événements
(
Routine.new({
	Synth(\samplePlayer, [out: 0, bufnum: ~clap]);
	1.0.wait; // attendre 1 temps = 1 seconde au tempo par défaut de 60 bpm
	Synth(\samplePlayer, [out: 0, bufnum: ~clap]);
}).play;
)

// il y a tout une librairie de patterns qui permettent de séquencer plus facilement
// lire le Pattern Guide
(
~pattern = Pn(Pseq([1, 2]), 2); // 1 seconde de pause, puis 2, repété 2 fois
~stream = ~pattern.asStream;

Routine.new( {
	var delta;
    while {
        delta = ~stream.next;
        delta.notNil
	}  {
		Synth(\samplePlayer, [out: 0, bufnum: ~clap]);
		delta.wait;
	}
}).play;
)

// on rentre dans le dur, on joue clapping music !
(
TempoClock.default.tempo = 100/60;

{
	~pattern = Pseq([1,1,2,1,2,2,1,2]);
	(0..7).do( {|i|
		var stream, time;
		stream = ~pattern.asStream;

		(0..7).do( {|j|
			// joueur 1
			Synth(\samplePlayer, [out: 0, bufnum: ~clap1Samples.choose]);
			Synth(\samplePlayer, [out: 0, bufnum: ~clap2Samples.choose]);
			// Synth(\fakeClap);
			(stream.next / 4).wait;
		});
	});

	(1..12).do( {|i|
		4.do({
			var streamg, streamd;
			~patterng = Pseq([1,1,1,0,1,1,0,1,0,1,1,0]);
			~patternd = Pslide(list: [1,1,1,0,1,1,0,1,0,1,1,0], len: 12, start: i);
			streamg = ~patterng.asStream;
			streamd = ~patternd.asStream;

			(0..11).do( { |j|
				if (streamg.next == 1) {
					Synth(\samplePlayer, [out: 0, bufnum: ~clap1Samples.choose]);
				};
				if (streamd.next == 1) {
					Synth(\samplePlayer, [out: 1, bufnum: ~clap2Samples.choose]);
					// si vous voulez utiliser le clap synthétique, remplacez par :
					// Synth(\fakeClap);
				};
				(1 / 4).wait; // 1 double croche à 100 bpm
			});
		});
	});
}.fork; // { }.fork est du sucre syntaxique pour Routine.new({ }).play
)

