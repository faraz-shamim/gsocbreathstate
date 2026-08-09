import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sanctuary V3 foundation', () {
    test('uses V3 by default and retains the temporary V2 rollback', () {
      final source = File('web/vr/webxr_biofeedback.js').readAsStringSync();

      expect(source, contains("urlParams.get('scene')"));
      expect(source, contains("requestedSceneVersion === 'v2' ? 'v2' : 'v3'"));
      expect(source, contains('initializeSceneV2Assets();'));
      expect(source, contains('sanctuarySceneV3.initialize'));
    });

    test('defines dedicated interaction layers', () {
      final source =
          File('web/vr/sanctuary_v3/sanctuary_scene.js').readAsStringSync();

      expect(source, contains('interactive: 1'));
      expect(source, contains('clinical: 2'));
      expect(source, contains('effects: 3'));
      expect(source, contains("this.root.name = 'SanctuaryV3_Root'"));

      final hostSource = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(
        hostSource,
        contains(
          'controllerRaycaster.layers.set(SANCTUARY_LAYERS.interactive)',
        ),
      );
      expect(hostSource, contains('eyeCamera.layers.enableAll()'));
    });

    test('ships the refined Phase 1 sakura package', () {
      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['phase'], 18);
      expect(manifest['version'], 25);
      expect(
        manifest['status'],
        'minimal-xr-controls-trend-canopy-audio-performance',
      );

      final runtimeAssets = manifest['runtimeAssets'] as Map<String, dynamic>;
      final heroSakura = runtimeAssets['heroSakura'] as Map<String, dynamic>;
      expect(heroSakura['quest'], 'tree/sakura_hero_lod0.glb');
      expect(
        File('web/vr/assets/sanctuary_v3/${heroSakura['quest']}').existsSync(),
        isTrue,
      );

      final treeProfile = manifest['treeProfile'] as Map<String, dynamic>;
      expect(treeProfile['targetHeightMeters'], 9.0);
      expect(treeProfile['sourceCanopyLayers'], 1);
      expect(treeProfile['dynamicCanopyLayers'], 2);
      expect(
        (manifest['fallback']
            as Map<String, dynamic>)['requiresExternalAssets'],
        isFalse,
      );
    });

    test('retains the original sakura and gates the branch-aware canopy', () {
      final source =
          File('web/vr/sanctuary_v3/sanctuary_scene.js').readAsStringSync();

      expect(source, contains('TREE_TARGET_HEIGHT = 9'));
      expect(source, isNot(contains('const canopyLayerSpecs')));
      expect(source, isNot(contains('Sakura_Blossom_Canopy_Layer_')));
      expect(source, contains('this.canopyLayers = 1'));
      expect(source, contains("canopyModeOverride === 'source'"));
      expect(source, contains("return 'dynamic'"));
      expect(source, contains('SakuraCanopyController'));
      expect(
        source,
        contains(
          "this.canopyLayers = canopySnapshot.canopyStatus === 'ready' ? 2 : 1",
        ),
      );
      expect(source, contains('object.layers.set(SANCTUARY_LAYERS.scenery)'));
      expect(source, contains('comfortOptions?.reducedMotion'));
    });

    test('keeps WebXR runtime dependencies local and inventoried', () {
      final html = File('web/vr/webxr_scene.html').readAsStringSync();
      expect(html, isNot(contains('unpkg.com')));
      expect(
        html,
        contains('"three": "./vendor/three/0.164.1/build/three.module.js"'),
      );
      expect(
        html,
        contains('"three/addons/": "./vendor/three/0.164.1/examples/jsm/"'),
      );

      final inventory =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/inventory.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final files = inventory['files'] as List<dynamic>;
      final paths =
          files
              .cast<Map<String, dynamic>>()
              .map((entry) => entry['path'])
              .toSet();
      expect(paths, contains('vendor/three/0.164.1/build/three.module.js'));
      expect(paths, contains('assets/sanctuary_v3/tree/sakura_hero_lod0.glb'));
      expect(paths, contains('sanctuary_v3/sanctuary_canopy.js'));
      expect(paths, contains('sanctuary_v3/sanctuary_canopy_math.js'));
      expect(paths, contains('sanctuary_v3/sanctuary_canopy_profiler.js'));
      expect(paths, contains('sanctuary_v3/sanctuary_validation_cycle.js'));

      expect(File('tool/vr_sanctuary_v3_pipeline.py').existsSync(), isTrue);
      expect(File('tool/build_vr_sanctuary_v3.ps1').existsSync(), isTrue);
      expect(File('tool/optimize_vr_glb.ps1').existsSync(), isTrue);
    });

    test('supports native Android host messaging over WebSocket', () {
      final host = File('web/vr/webxr_biofeedback.js').readAsStringSync();

      expect(host, contains("urlParams.get('bridgeToken')"));
      expect(host, contains("new URL('/bridge'"));
      expect(host, contains('new WebSocket(endpoint)'));
      expect(host, contains('nativeSocket.send(JSON.stringify(message))'));
      expect(host, contains("new BroadcastChannel('breathstate_hrv_vr')"));
      expect(host, contains('applyDemoSessionCommand'));
      expect(host, contains('commandUiState'));
      expect(host, contains('pulseController'));
    });

    test('packages landscape LODs and terrain-following animated grass', () {
      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final runtimeAssets = manifest['runtimeAssets'] as Map<String, dynamic>;
      final landscape = runtimeAssets['landscape'] as Map<String, dynamic>;
      for (final key in ['quest', 'fallbackLod', 'high']) {
        expect(
          File('web/vr/assets/sanctuary_v3/${landscape[key]}').existsSync(),
          isTrue,
        );
      }

      final grassProfile = manifest['grassProfile'] as Map<String, dynamic>;
      expect(grassProfile['questInstances'], 96000);
      expect(
        grassProfile['questEstimatedTriangles'],
        lessThanOrEqualTo(1800000),
      );
      expect(
        File(
          'web/vr/assets/sanctuary_v3/${landscape['authoredGrassVariants']}',
        ).existsSync(),
        isTrue,
      );

      final source =
          File('web/vr/sanctuary_v3/sanctuary_landscape.js').readAsStringSync();
      expect(source, contains('class TerrainHeightSampler'));
      expect(source, contains('THREE.InstancedMesh'));
      expect(source, contains('attribute float grassFlex'));
      expect(source, contains('comfortOptions?.reducedMotion'));
      expect(source, contains('animated_grass_variants.glb'));
      expect(source, contains('GOLDEN_ANGLE'));
      expect(source, contains('RADIAL_LOW_DISCREPANCY'));
      expect(
        source,
        contains("grassAbundancePolicy = 'constant-full-density'"),
      );
      expect(source, contains('grassResonanceReactive: false'));
      expect(source, isNot(contains('uGrassVitality')));
      expect(source, contains('LANDSCAPE_RELIEF_SCALE = 0.68'));
      expect(source, contains('landscape.rotation.y += Math.PI'));
      expect(source, contains('this.normals = new Float32Array'));
    });

    test(
      'packages signal-safe coherence state and animated falling petals',
      () {
        final stateSource =
            File(
              'web/vr/sanctuary_v3/sanctuary_tree_state.js',
            ).readAsStringSync();
        expect(stateSource, contains('SanctuaryTreeVisualState'));
        expect(stateSource, contains('signalAccepted'));
        expect(stateSource, contains('vitalityRate = improving ? 0.28 : 0.22'));
        expect(stateSource, contains('difference < -0.016'));
        expect(stateSource, contains('trendResponsiveCoverageTargets'));
        expect(stateSource, contains('coherenceTrend'));
        expect(stateSource, contains('leafCoverage'));
        expect(stateSource, contains('canopyHealth'));
        expect(stateSource, contains('fullBloomProgress'));
        expect(stateSource, contains('coherence >= 0.95'));
        expect(stateSource, contains('coherence < 0.88'));

        final canopySource =
            File('web/vr/sanctuary_v3/sanctuary_canopy.js').readAsStringSync();
        expect(canopySource, contains('SakuraCanopyController'));
        expect(canopySource, contains('extractAuthoredCanopyAnchors'));
        expect(canopySource, contains('sakura_sakura_mat'));
        expect(canopySource, contains('THREE.InstancedMesh'));
        expect(canopySource, contains('instanceUvRect'));
        expect(canopySource, contains('clinicalShedEventRate'));
        expect(canopySource, contains('drainShedEvents'));
        expect(canopySource, contains('totalDetachedPetals'));
        expect(
          canopySource,
          contains('SanctuaryV3_Authored_Full_Bloom_Canopy'),
        );
        expect(canopySource, contains('canopyCardCenter'));
        expect(canopySource, contains('canopyCardSeed'));
        expect(canopySource, contains('FULL_BLOOM_GROWTH_RATE = 0.25'));
        expect(canopySource, contains('fullBloomLightPulse'));
        expect(canopySource, contains('isClinicalDetachment'));
        expect(canopySource, contains('clinicalBlossomTargetCount'));
        expect(canopySource, contains('clinicalBlossomRenderBoundary'));
        expect(canopySource, contains('clinicalDetachmentAllowance'));
        expect(canopySource, contains('totalAdaptiveRetractions'));
        expect(
          canopySource,
          isNot(
            contains("comfortOptions?.reducedParticles === true ? 0.65 : 1"),
          ),
        );
        expect(canopySource, contains('reducedMotion ? 0.08 : 0.48'));
        expect(canopySource, contains('canopyIntegrityIssue'));
        expect(canopySource, contains('canopyIntegrityFailures'));
        expect(canopySource, contains('RENDER_GREEN_LEAF_LAYER = false'));
        expect(
          canopySource,
          contains("canopyPresentation: 'sakura-blossoms-only'"),
        );
        expect(canopySource, contains('this.root.add(this.blossomLayer.mesh)'));
        final canopyMathSource =
            File(
              'web/vr/sanctuary_v3/sanctuary_canopy_math.js',
            ).readAsStringSync();
        expect(canopyMathSource, contains('maxLeaves: 900'));
        expect(canopyMathSource, contains('maxBlossoms: 720'));

        final petalSource =
            File('web/vr/sanctuary_v3/sanctuary_petals.js').readAsStringSync();
        expect(petalSource, contains('THREE.InstancedMesh'));
        expect(petalSource, contains('THREE.AnimationMixer'));
        expect(petalSource, contains('falling_leaves_animated_quest.glb'));
        expect(petalSource, contains("fallingRenderer = 'animated-glb'"));
        expect(
          petalSource,
          contains('USE_AUTHORED_NON_SAKURA_LEAF_ANIMATION = false'),
        );
        expect(petalSource, contains("'instanced-quest'"));
        expect(petalSource, contains('ANIMATED_PETAL_TARGET_HEIGHT = 5.7'));
        expect(petalSource, contains('ANIMATED_PETAL_GEOMETRY_SCALE = 0.18'));
        expect(petalSource, contains('ANIMATED_PETAL_DEPTH_OFFSET = -2.0'));
        expect(petalSource, contains('shrinkAnimatedPetalGeometry'));
        expect(petalSource, contains('coherenceToFallingIntensity'));
        expect(petalSource, contains('clampedCoherence >= 0.995'));
        expect(petalSource, contains('material.map = null'));
        expect(petalSource, contains('material.color.set(0xff83ad)'));
        expect(petalSource, contains('SanctuaryV3_Sakura_Petal_Geometry'));
        expect(
          petalSource,
          contains("fallingPetalGeometry: 'curved-notched-sakura-petal'"),
        );
        expect(petalSource, isNot(contains('map: texture')));
        expect(petalSource, contains('SanctuaryV3_Exact_Origin_Petals'));
        expect(petalSource, contains('enqueueShedEvents'));
        expect(petalSource, contains("quality === 'high' ? 160 : 96"));
        expect(petalSource, contains('maximumCoherence'));
        expect(petalSource, contains('visualState?.fullBloom === true'));
        expect(petalSource, contains('eventDrivenShedding'));

        final sceneSource =
            File('web/vr/sanctuary_v3/sanctuary_scene.js').readAsStringSync();
        final bridgeSource =
            File('web/vr/webxr_biofeedback.js').readAsStringSync();
        expect(
          sceneSource,
          contains('coherence: fallingCoherence ?? coherence'),
        );
        expect(
          sceneSource,
          contains('this.canopyController.drainShedEvents()'),
        );
        expect(
          sceneSource,
          contains("canopySnapshot.canopyMode === 'dynamic'"),
        );
        expect(sceneSource, contains('TREE_FULL_BLOOM_COLOR'));
        expect(sceneSource, contains('fullBloomPulse * 0.75'));
        expect(sceneSource, contains('CanopyTransitionProfiler'));
        expect(sceneSource, contains('this.canopyPerformanceSnapshot'));

        final canopyProfilerSource =
            File(
              'web/vr/sanctuary_v3/sanctuary_canopy_profiler.js',
            ).readAsStringSync();
        expect(canopyProfilerSource, contains('canopyTransitionFrames'));
        expect(bridgeSource, contains("urlParams.get('canopyTest')"));
        expect(bridgeSource, contains('canopyValidationSample'));
        expect(bridgeSource, contains('liveDataAuthoritative: !demoMode'));
        expect(bridgeSource, contains('validationTreeVitality'));
        expect(bridgeSource, contains('fallingCoherence: state.coherence'));
        expect(petalSource, contains('mergeGeometries'));
        expect(petalSource, contains('reducedParticles'));
        expect(petalSource, contains('Math.min(54, performanceLimit)'));
        expect(
          petalSource,
          contains('this.maxFallingPetals * performanceScale'),
        );

        final manifest =
            jsonDecode(
                  File(
                    'web/vr/assets/sanctuary_v3/manifest.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final runtimeAssets = manifest['runtimeAssets'] as Map<String, dynamic>;
        final petals = runtimeAssets['petals'] as Map<String, dynamic>;
        expect(
          File(
            'web/vr/assets/sanctuary_v3/${petals['animatedFalling']}',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            'web/vr/assets/sanctuary_v3/${petals['fallingTexture']}',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            'web/vr/assets/sanctuary_v3/${petals['groundPatches']}',
          ).existsSync(),
          isTrue,
        );
        expect(runtimeAssets.toString(), isNot(contains('cherry_petals1.glb')));
      },
    );

    test('packages terrain-aligned organic details within Quest budgets', () {
      final source =
          File('web/vr/sanctuary_v3/sanctuary_details.js').readAsStringSync();
      expect(source, contains('SanctuaryGroundDetails'));
      expect(source, contains('THREE.InstancedMesh'));
      expect(source, contains('terrainSampler?.sample'));
      expect(source, contains('terrainSampler?.normal'));
      expect(source, contains('blocksCentralView'));
      expect(source, contains('definition.questCount ?? definition.count'));
      expect(source, contains('object.isInstancedMesh'));
      expect(source, contains('mergeGeometries'));

      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final runtimeAssets = manifest['runtimeAssets'] as Map<String, dynamic>;
      final details = runtimeAssets['organicDetails'] as Map<String, dynamic>;
      final paths = <String>[
        ...((details['rocks'] as List<dynamic>).cast<String>()),
        ...((details['flowers'] as List<dynamic>).cast<String>()),
        ...((details['bushes'] as List<dynamic>).cast<String>()),
      ];
      expect(paths, hasLength(12));
      for (final path in paths) {
        expect(File('web/vr/assets/sanctuary_v3/$path').existsSync(), isTrue);
      }

      final profile = manifest['organicDetailProfile'] as Map<String, dynamic>;
      expect(profile['questInstances'], 102);
      expect(profile['questEstimatedTriangles'], lessThanOrEqualTo(340000));
      expect(profile['qualityPolicy'], contains('bush3'));
      expect(source, contains("assetFile: 'glowing_plants_parts_quest.glb'"));
      expect(source, contains("'glowLeaf'"));
      expect(source, contains("'glowOrb'"));
      expect(source, contains('material.emissive.set(0x9b42e6)'));
    });

    test('packages the comfort-aware nocturnal atmosphere', () {
      final source =
          File(
            'web/vr/sanctuary_v3/sanctuary_atmosphere.js',
          ).readAsStringSync();
      expect(source, contains('SanctuaryAtmosphere'));
      expect(source, contains('SanctuaryV3_Twinkling_Stars'));
      expect(source, contains('SanctuaryV3_Warm_Fireflies'));
      expect(source, contains('SanctuaryV3_Hyperreal_Moon'));
      expect(source, contains('createAuroraMaterial'));
      expect(source, contains('comfortOptions?.reducedMotion'));
      expect(source, contains('comfortOptions?.reducedParticles'));
      expect(source, contains('Math.round(this.fireflyCount * 0.28)'));
      expect(source, contains('pow(primaryTwinkle, 2.8)'));
      expect(source, contains('pow(blinkWave, 3.4)'));
      expect(source, contains('alpha * vFireflyGlow < 0.008'));

      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final runtimeAssets = manifest['runtimeAssets'] as Map<String, dynamic>;
      final atmosphere = runtimeAssets['atmosphere'] as Map<String, dynamic>;
      for (final path in atmosphere.values.cast<String>()) {
        expect(File('web/vr/assets/sanctuary_v3/$path').existsSync(), isTrue);
      }
      final profile = manifest['atmosphereProfile'] as Map<String, dynamic>;
      expect(profile['questStars'], 50000);
      expect(profile['questFireflies'], 900);
      expect(profile['auroraTriangles'], lessThanOrEqualTo(30000));
      expect(profile['moonTriangles'], lessThanOrEqualTo(4500));
    });

    test('integrates environmental guidance and XR quality protection', () {
      final guideSource =
          File('web/vr/sanctuary_v3/sanctuary_guidance.js').readAsStringSync();
      expect(guideSource, contains('SanctuaryBreathingGuide'));
      expect(guideSource, contains('SanctuaryV3_Soft_Breathing_Ring'));
      expect(guideSource, contains('highContrastGuide'));
      expect(guideSource, contains('reducedMotion'));
      expect(guideSource, contains('sessionPaused'));

      final performanceSource =
          File(
            'web/vr/sanctuary_v3/sanctuary_performance.js',
          ).readAsStringSync();
      expect(performanceSource, contains('SanctuaryPerformanceGovernor'));
      expect(performanceSource, contains("quality === 'quest'"));
      expect(performanceSource, contains('this.sampleCount < 120'));
      expect(performanceSource, contains('this.slowScore >= 60'));
      expect(performanceSource, contains('this.fastScore >= 900'));

      final hostSource = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(hostSource, contains('xrPresenting: renderer.xr.isPresenting'));
      expect(hostSource, contains('sessionActive: sessionState.active'));
      expect(hostSource, contains('sessionPaused: sessionState.paused'));

      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final quality =
          manifest['adaptiveQualityProfile'] as Map<String, dynamic>;
      expect(quality['enabledQuality'], 'quest');
      expect(quality['protectedContent'], contains('controller hit targets'));
    });

    test('cannot leave the VR startup overlay pending forever', () {
      final html = File('web/vr/webxr_scene.html').readAsStringSync();
      expect(html, contains('window.__breathStateVrBoot'));
      expect(html, contains("import('./webxr_biofeedback.js?v=25')"));
      expect(html, contains('VR module request timed out'));
      expect(html, contains('loadingRetry'));
      expect(html, contains("window.addEventListener('unhandledrejection'"));

      final host = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(host, contains('loadingWatchdog = setTimeout'));
      expect(host, contains('remaining assets continue loading'));
      expect(host, contains('Renderer did not initialize within 25 seconds'));
      expect(host, contains("sanctuarySceneV3.ready.then"));
      expect(host, contains("}).catch((error) =>"));

      for (final path in [
        'web/vr/sanctuary_v3/sanctuary_scene.js',
        'web/vr/sanctuary_v3/sanctuary_landscape.js',
        'web/vr/sanctuary_v3/sanctuary_details.js',
        'web/vr/sanctuary_v3/sanctuary_petals.js',
        'web/vr/sanctuary_v3/sanctuary_atmosphere.js',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('Timed out loading'));
        expect(source, contains('12000'));
      }
    });

    test('hardens Quest renderer and XR lifecycle recovery', () {
      final host = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(
        host,
        contains('framebufferScale: questRendererPolicy ? 0.78 : 1'),
      );
      expect(host, contains('renderer.xr.setFramebufferScaleFactor'));
      expect(host, contains('renderer.xr.setFoveation'));
      expect(host, contains('session.updateTargetFrameRate(target)'));
      expect(host, contains("level === 'protected'"));
      expect(host, contains("webglcontextlost"));
      expect(host, contains("webglcontextrestored"));
      expect(host, contains("renderer.xr.addEventListener('sessionend'"));
      expect(host, contains("document.addEventListener('visibilitychange'"));
      expect(host, contains('window.getBreathStateVrDiagnostics'));
      expect(host, contains("urlParams.get('perfTier')"));

      final performanceSource =
          File(
            'web/vr/sanctuary_v3/sanctuary_performance.js',
          ).readAsStringSync();
      expect(performanceSource, contains('grassZoneAbundance'));
      expect(performanceSource, contains('detailAssetAbundance'));
      expect(performanceSource, contains('quantizePerformanceScale'));
      expect(performanceSource, contains('performanceTierForced'));

      final manifest =
          jsonDecode(
                File(
                  'web/vr/assets/sanctuary_v3/manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final release =
          manifest['releaseHardeningProfile'] as Map<String, dynamic>;
      final renderer = release['questRenderer'] as Map<String, dynamic>;
      expect(renderer['xrFramebufferScale'], 0.78);
      expect(renderer['initialFoveation'], 0.78);
      expect(renderer['protectedFoveation'], 1.0);
      expect(release['diagnostics'], contains('excludes patient IDs'));

      final runtimeEfficiency =
          manifest['runtimeEfficiencyProfile'] as Map<String, dynamic>;
      expect(runtimeEfficiency['profileSamplingHz'], 4);
      expect(runtimeEfficiency['adaptiveRangeStep'], 0.02);
      expect(runtimeEfficiency['grassShading'], 'lambert-quest');
      expect(runtimeEfficiency['moduleGraphVersion'], 25);
      expect(
        host,
        contains('const sanctuaryFrameState = sanctuarySceneV3?.update'),
      );
      expect(host, contains('lastProfileStateSample'));
    });

    test('keeps only essential session actions inside the headset', () {
      final host = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(host, contains("addCommandButton('Start'"));
      expect(host, contains("addCommandButton('Pause'"));
      expect(host, contains("addCommandButton('Resume'"));
      expect(host, contains("addCommandButton('Stop'"));
      expect(host, isNot(contains('SESSION CONTROLS')));
      expect(host, isNot(contains("addCommandButton('Low motion'")));
      expect(host, isNot(contains("addCommandButton('Fewer effects'")));

      final screen =
          File('lib/screens/vr_biofeedback_screen.dart').readAsStringSync();
      expect(screen, contains('BreathingSoundProvider'));
      expect(screen, contains('_syncVrBreathingAudio'));
      expect(screen, contains('BreathingSoundToggle'));
    });

    test('uses fixed comfort defaults without redundant toolbar controls', () {
      final host = File('web/vr/webxr_biofeedback.js').readAsStringSync();
      expect(host, contains('seatedMode: true'));
      expect(host, contains('reducedMotion: false'));
      expect(host, contains('reducedParticles: false'));
      expect(host, contains('highContrastGuide: true'));
      expect(host, isNot(contains("addComfortButton('Seated'")));
      expect(host, isNot(contains("addComfortButton('Motion'")));
      expect(host, isNot(contains("addComfortButton('Particles'")));
      expect(host, isNot(contains("addComfortButton('Contrast'")));
      expect(host, isNot(contains("addComfortButton('Text'")));

      final screen =
          File('lib/screens/vr_biofeedback_screen.dart').readAsStringSync();
      expect(screen, contains('bool _seatedMode = true'));
      expect(screen, contains('bool _reducedMotion = false'));
      expect(screen, contains('bool _reducedParticles = false'));
      expect(screen, contains('bool _highContrastGuide = true'));
      expect(screen, isNot(contains("label: 'Seated'")));
      expect(screen, isNot(contains("label: 'Reduced motion'")));
      expect(screen, isNot(contains("label: 'Fewer particles'")));
      expect(screen, isNot(contains("label: 'High contrast'")));
      expect(screen, isNot(contains("label: 'Larger text'")));
    });
  });
}
